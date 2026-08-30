#!/usr/bin/env python3
import hashlib
import json
import os
import urllib.request
import zipfile
from collections import defaultdict
from io import BytesIO
from pathlib import Path
from xml.etree import ElementTree as ET

SOURCE_URL = "https://geoftp.ibge.gov.br/organizacao_do_territorio/estrutura_territorial/divisao_territorial/2025/DTB_2025.zip"
EXPECTED_SOURCE_SHA256 = "d077a0e48c36cf18bcc96268b4a436200c014c6b8522c1a62d894acaf39dad27"
MUNICIPALITY_MEMBER = "RELATORIO_DTB_BRASIL_2025_MUNICIPIOS.ods"
EXPECTED_MEMBER_SHA256 = "a0606b9706c248138131511287e582a9293ba786096e0395192be36108d029fa"
EXPECTED_CITY_LEVEL_ROW_COUNT = 5571
EXPECTED_MUNICIPALITY_COUNT = 5569
SPECIAL_CITY_LEVEL_CODES = {"2605459", "5300108"}
CASES = Path("benchmarks/ibge-municipality-identity/cases-v1.json")
OUTPUT = Path(os.environ.get("BPT_IBGE_MUNICIPALITY_OUTPUT", "artifacts/ibge-municipality-identity-baseline.json"))

NS = {
    "table": "urn:oasis:names:tc:opendocument:xmlns:table:1.0",
    "text": "urn:oasis:names:tc:opendocument:xmlns:text:1.0",
}
UF_CODE_TO_ABBR = {
    "11": "RO", "12": "AC", "13": "AM", "14": "RR", "15": "PA", "16": "AP", "17": "TO",
    "21": "MA", "22": "PI", "23": "CE", "24": "RN", "25": "PB", "26": "PE", "27": "AL",
    "28": "SE", "29": "BA", "31": "MG", "32": "ES", "33": "RJ", "35": "SP", "41": "PR",
    "42": "SC", "43": "RS", "50": "MS", "51": "MT", "52": "GO", "53": "DF",
}
EXPECTED_HEADERS = [
    "UF", "Nome_UF", "Região Geográfica Intermediária", "Nome Região Geográfica Intermediária",
    "Região Geográfica Imediata", "Nome Região Geográfica Imediata", "Município",
    "Código Município Completo", "Nome_Município",
]


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def cell_text(cell):
    return " ".join("".join(p.itertext()).strip() for p in cell.findall(".//text:p", NS)).strip()


def ods_rows(ods_payload):
    with zipfile.ZipFile(BytesIO(ods_payload)) as ods:
        root = ET.fromstring(ods.read("content.xml"))
    for row in root.findall(".//table:table-row", NS):
        values = []
        for cell in row.findall("./table:table-cell", NS):
            repeat = int(cell.attrib.get(f"{{{NS['table']}}}number-columns-repeated", "1"))
            value = cell_text(cell)
            values.extend([value] * min(repeat, 50))
        while values and values[-1] == "":
            values.pop()
        if any(values):
            yield values


def acquire():
    request = urllib.request.Request(SOURCE_URL, headers={"User-Agent": "BPT2 municipality identity benchmark/1.0"})
    with urllib.request.urlopen(request, timeout=60) as response:
        payload = response.read()
    actual = hashlib.sha256(payload).hexdigest()
    require(actual == EXPECTED_SOURCE_SHA256, f"DTB source digest changed: {actual}")
    return payload


def parse_city_level_rows(source_payload):
    with zipfile.ZipFile(BytesIO(source_payload)) as archive:
        member_payload = archive.read(MUNICIPALITY_MEMBER)
    member_sha = hashlib.sha256(member_payload).hexdigest()
    require(member_sha == EXPECTED_MEMBER_SHA256, f"Municipality member digest changed: {member_sha}")

    rows = list(ods_rows(member_payload))
    header_index = next((i for i, row in enumerate(rows) if row[:9] == EXPECTED_HEADERS), None)
    require(header_index is not None, "Municipality headers not found")

    city_level_rows = []
    for row in rows[header_index + 1:]:
        if len(row) < 9:
            continue
        uf_numeric, code, city = row[0], row[7], row[8]
        if not (len(uf_numeric) == 2 and uf_numeric.isdigit() and len(code) == 7 and code.isdigit() and city):
            continue
        state = UF_CODE_TO_ABBR.get(uf_numeric)
        require(state is not None, f"Unknown UF numeric code {uf_numeric}")
        require(code.startswith(uf_numeric), f"City-level code {code} does not start with UF {uf_numeric}")
        entity_kind = "SPECIAL_CITY_LEVEL_UNIT" if code in SPECIAL_CITY_LEVEL_CODES else "MUNICIPALITY"
        city_level_rows.append({
            "city": city,
            "stateCode": state,
            "municipalityCode": code,
            "entityKind": entity_kind,
        })

    require(len(city_level_rows) == EXPECTED_CITY_LEVEL_ROW_COUNT,
            f"Expected {EXPECTED_CITY_LEVEL_ROW_COUNT} coded city-level rows, got {len(city_level_rows)}")
    require(len({item['municipalityCode'] for item in city_level_rows}) == EXPECTED_CITY_LEVEL_ROW_COUNT,
            "City-level codes are not unique")
    municipality_count = sum(1 for item in city_level_rows if item["entityKind"] == "MUNICIPALITY")
    special_count = sum(1 for item in city_level_rows if item["entityKind"] == "SPECIAL_CITY_LEVEL_UNIT")
    require(municipality_count == EXPECTED_MUNICIPALITY_COUNT,
            f"Expected {EXPECTED_MUNICIPALITY_COUNT} municipalities after special-unit separation, got {municipality_count}")
    require(special_count == 2, f"Expected 2 special city-level units, got {special_count}")
    require({item['municipalityCode'] for item in city_level_rows if item['entityKind'] == 'SPECIAL_CITY_LEVEL_UNIT'} == SPECIAL_CITY_LEVEL_CODES,
            "Special city-level code set changed")
    return city_level_rows, member_sha


def evaluate(city_level_rows):
    by_exact_key = defaultdict(list)
    by_city = defaultdict(list)
    for item in city_level_rows:
        by_exact_key[(item["city"], item["stateCode"])].append(item)
        by_city[item["city"]].append(item)

    duplicate_exact_keys = [
        {"city": key[0], "stateCode": key[1], "codes": [x["municipalityCode"] for x in items]}
        for key, items in by_exact_key.items() if len(items) > 1
    ]
    require(not duplicate_exact_keys, "Exact City+UF authority contains duplicate keys")

    fixture = json.loads(CASES.read_text(encoding="utf-8"))
    results = []
    for case in fixture["cases"]:
        candidates = by_exact_key.get((case["city"], case["stateCode"]), [])
        status = "UNMATCHED" if not candidates else ("EXACT" if len(candidates) == 1 else "AMBIGUOUS")
        code = candidates[0]["municipalityCode"] if len(candidates) == 1 else None
        entity_kind = candidates[0]["entityKind"] if len(candidates) == 1 else None
        require(status == case["expectedStatus"], f"{case['id']}: expected {case['expectedStatus']}, got {status}")
        require(code == case["expectedMunicipalityCode"], f"{case['id']}: expected code {case['expectedMunicipalityCode']}, got {code}")
        require(entity_kind == case["expectedEntityKind"], f"{case['id']}: expected kind {case['expectedEntityKind']}, got {entity_kind}")
        results.append({
            "id": case["id"], "city": case["city"], "stateCode": case["stateCode"],
            "status": status, "municipalityCode": code, "entityKind": entity_kind,
            "candidateCount": len(candidates),
        })

    cross_uf_reused_names = sum(1 for items in by_city.values() if len({x["stateCode"] for x in items}) > 1)
    return fixture, results, duplicate_exact_keys, cross_uf_reused_names


def main():
    source_payload = acquire()
    city_level_rows, member_sha = parse_city_level_rows(source_payload)
    fixture, results, duplicate_exact_keys, cross_uf_reused_names = evaluate(city_level_rows)

    exact = sum(1 for result in results if result["status"] == "EXACT")
    unmatched = sum(1 for result in results if result["status"] == "UNMATCHED")
    ambiguous = sum(1 for result in results if result["status"] == "AMBIGUOUS")
    municipality_count = sum(1 for item in city_level_rows if item["entityKind"] == "MUNICIPALITY")
    special_rows = [item for item in city_level_rows if item["entityKind"] == "SPECIAL_CITY_LEVEL_UNIT"]
    output = {
        "schema": "bpt2.ibge-municipality-identity-baseline.v1",
        "source": {
            "authority": "IBGE", "product": "Divisão Territorial Brasileira", "edition": 2025,
            "dataBase": "31/12/2025", "url": SOURCE_URL, "sha256": EXPECTED_SOURCE_SHA256,
            "municipalityMember": MUNICIPALITY_MEMBER, "municipalityMemberSha256": member_sha,
        },
        "authority": {
            "codedCityLevelRowCount": len(city_level_rows),
            "municipalityCount": municipality_count,
            "specialCityLevelUnits": special_rows,
            "uniqueCodeCount": len({x["municipalityCode"] for x in city_level_rows}),
            "duplicateExactCityUfKeys": duplicate_exact_keys,
            "cityNamesReusedAcrossMultipleUfs": cross_uf_reused_names,
        },
        "fixture": {"schema": fixture["schema"], "matchingRule": fixture["matchingRule"], "caseCount": len(results)},
        "metrics": {"exact": exact, "unmatched": unmatched, "ambiguous": ambiguous},
        "cases": results,
        "decision": {
            "municipalityIdentityAuthority": "IBGE_DTB_2025_PINNED",
            "exactCityUfProjection": "PROVED_BOUNDED",
            "specialCityLevelUnits": "PRESERVE_EXPLICITLY_DO_NOT_MISCLASSIFY_AS_ORDINARY_MUNICIPALITY",
            "heuristicNormalization": "NOT_AUTHORIZED",
            "trueListingRadius": "STILL_BLOCKED_ON_LOCATION_POINT_AUTHORITY_AND_PRIVACY",
            "centroidRadius": "NOT_PROVED_BY_THIS_BENCHMARK",
            "postgis": "NOT_SELECTED",
        },
    }
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(output, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"IBGE_CODED_CITY_LEVEL_ROWS={len(city_level_rows)}")
    print(f"IBGE_MUNICIPALITIES={municipality_count}")
    print(f"IBGE_SPECIAL_CITY_LEVEL_UNITS={len(special_rows)}")
    print(f"IBGE_CROSS_UF_REUSED_NAMES={cross_uf_reused_names}")
    print(f"BPT_FIXTURE_EXACT={exact}")
    print(f"BPT_FIXTURE_UNMATCHED={unmatched}")
    print(f"BPT_FIXTURE_AMBIGUOUS={ambiguous}")
    print("IBGE_MUNICIPALITY_IDENTITY_BASELINE=PASS")
    print(f"IBGE_MUNICIPALITY_IDENTITY_ARTIFACT={OUTPUT}")


if __name__ == "__main__":
    main()
