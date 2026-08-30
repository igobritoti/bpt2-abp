#!/usr/bin/env python3
import hashlib
import json
import os
import urllib.request
import zipfile
from io import BytesIO
from pathlib import Path
from xml.etree import ElementTree as ET

SOURCE_URL = "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/divisao_territorial/2025/DTB_2025.zip"
EXPECTED_SHA256 = "d077a0e48c36cf18bcc96268b4a436200c014c6b8522c1a62d894acaf39dad27"
MUNICIPALITY_MEMBER = "RELATORIO_DTB_BRASIL_2025_MUNICIPIOS.ods"
OUTPUT = Path(os.environ.get("BPT_IBGE_DTB_OBSERVATION", "artifacts/ibge-dtb-2025-source-observation.json"))

NS = {
    "table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
    "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
}


def cell_text(cell):
    return " ".join("".join(p.itertext()).strip() for p in cell.findall(".//text:p", NS)).strip()


def read_rows(ods_payload, limit=20):
    with zipfile.ZipFile(BytesIO(ods_payload)) as ods:
        root = ET.fromstring(ods.read("content.xml"))
    rows = []
    for row in root.findall(".//table:table-row", NS):
        values = []
        for cell in row.findall("./table:table-cell", NS):
            repeat = int(cell.attrib.get(f"{{{NS['table']}}}number-columns-repeated", "1"))
            value = cell_text(cell)
            values.extend([value] * min(repeat, 50))
        while values and values[-1] == "":
            values.pop()
        if any(values):
            rows.append(values)
            if len(rows) >= limit:
                break
    return rows


OUTPUT.parent.mkdir(parents=True, exist_ok=True)
request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "BPT2 evidence benchmark/1.0"})
with urllib.request.urlopen(request, timeout=60) as response:
    payload = response.read()

digest = hashlib.sha256(payload).hexdigest()
if digest != EXPECTED_SHA256:
    raise RuntimeError(f"IBGE DTB 2025 digest changed: expected {EXPECTED_SHA256}, got {digest}")

with zipfile.ZipFile(BytesIO(payload)) as archive:
    members = sorted(
        (
            {"name": info.filename, "size": info.file_size, "crc": f"{info.CRC:08x}"}
            for info in archive.infolist()
            if not info.is_dir()
        ),
        key=lambda item: item["name"],
    )
    municipality_payload = archive.read(MUNICIPALITY_MEMBER)

sample_rows = read_rows(municipality_payload)
observation = {
    "schema": "bpt2.ibge-dtb-source-observation.v2",
    "source": {
        "authority": "IBGE",
        "edition": 2025,
        "url": SOURCE_URL,
        "sha256": digest,
        "sizeBytes": len(payload),
        "municipalityMember": MUNICIPALITY_MEMBER,
        "municipalityMemberSha256": hashlib.sha256(municipality_payload).hexdigest(),
    },
    "archiveMembers": members,
    "municipalityTableSampleRows": sample_rows,
    "acceptanceGuard": {
        "municipalityIdentityAcceptanceAllowed": False,
        "reason": "Source SHA is pinned and municipality table headers are inspected, but exact City+UF matching has not yet been executed.",
    },
}
OUTPUT.write_text(json.dumps(observation, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"IBGE_DTB_2025_SHA256={digest}")
print(f"IBGE_MUNICIPALITY_MEMBER_SHA256={observation['source']['municipalityMemberSha256']}")
for index, row in enumerate(sample_rows):
    print(f"IBGE_MUNICIPALITY_ROW_{index}={json.dumps(row, ensure_ascii=False)}")
print(f"IBGE_DTB_OBSERVATION={OUTPUT}")
