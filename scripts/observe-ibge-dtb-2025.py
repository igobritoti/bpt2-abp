#!/usr/bin/env python3
import hashlib
import json
import os
import urllib.request
import zipfile
from pathlib import Path

SOURCE_URL = "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/divisao_territorial/2025/DTB_2025.zip"
OUTPUT = Path(os.environ.get("BPT_IBGE_DTB_OBSERVATION", "artifacts/ibge-dtb-2025-source-observation.json"))
RAW = Path("artifacts/DTB_2025.zip")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "BPT2 evidence benchmark/1.0"})
with urllib.request.urlopen(request, timeout=60) as response:
    payload = response.read()

RAW.write_bytes(payload)
digest = hashlib.sha256(payload).hexdigest()
with zipfile.ZipFile(RAW) as archive:
    members = sorted(
        {
            "name": info.filename,
            "size": info.file_size,
            "crc": f"{info.CRC:08x}",
        }
        for info in archive.infolist()
        if not info.is_dir()
    , key=lambda item: item["name"])

observation = {
    "schema": "bpt2.ibge-dtb-source-observation.v1",
    "source": {
        "authority": "IBGE",
        "edition": 2025,
        "url": SOURCE_URL,
        "sha256": digest,
        "sizeBytes": len(payload),
    },
    "archiveMembers": members,
    "acceptanceGuard": {
        "municipalityIdentityAcceptanceAllowed": False,
        "reason": "Observation records exact source bytes and archive structure only. Municipality parsing and City+UF matching are not yet executed or pinned.",
    },
}
OUTPUT.write_text(json.dumps(observation, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(f"IBGE_DTB_2025_SHA256={digest}")
print(f"IBGE_DTB_2025_SIZE={len(payload)}")
for member in members:
    print(f"IBGE_DTB_MEMBER={member['name']}|{member['size']}|{member['crc']}")
print(f"IBGE_DTB_OBSERVATION={OUTPUT}")
