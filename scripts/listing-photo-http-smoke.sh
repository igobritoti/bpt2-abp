#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5092}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-listing-photo-http.log"
SWAGGER="${TMPDIR:-/tmp}/bpt2-listing-photo-swagger.json"
ROUTES="${TMPDIR:-/tmp}/bpt2-listing-photo-routes.env"
RESPONSE="${TMPDIR:-/tmp}/bpt2-listing-photo-response.json"
PHOTO_RESPONSE="${TMPDIR:-/tmp}/bpt2-listing-photo-content.bin"
PHOTO_HEADERS="${TMPDIR:-/tmp}/bpt2-listing-photo-content.headers"
PNG="${TMPDIR:-/tmp}/bpt2-listing-photo.png"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export BPT_MEDIA_ROOT="${BPT_MEDIA_ROOT:-${TMPDIR:-/tmp}/bpt2-media-http}"
rm -rf "$BPT_MEDIA_ROOT"
mkdir -p "$BPT_MEDIA_ROOT"

# Valid 1x1 PNG. The server must identify the image from these bytes, not trust multipart metadata.
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$SWAGGER" ]] || { cat "$LOG" >&2; echo "Swagger did not become available." >&2; exit 1; }

python3 - "$SWAGGER" "$ROUTES" <<'PY'
import json
import re
import shlex
import sys

swagger_path, env_path = sys.argv[1:]
with open(swagger_path, encoding="utf-8") as handle:
    document = json.load(handle)
paths = document.get("paths", {})


def pick(fragment: str, verbs: tuple[str, ...], action: str | None = None, no_path_parameter: bool = False):
    candidates = []
    for path, operations in paths.items():
        if fragment not in path:
            continue
        if no_path_parameter and "{" in path:
            continue
        for verb in verbs:
            operation = operations.get(verb)
            if operation is None:
                continue
            haystack = f"{path} {operation.get('operationId', '')}".lower()
            if action and action.lower() not in haystack:
                continue
            candidates.append((path, verb, operation))
    if not candidates:
        raise SystemExit(
            f"Missing operation fragment={fragment!r}, verbs={verbs}, action={action!r}. Available: {sorted(paths)}"
        )
    return sorted(candidates, key=lambda item: (item[0].count("{"), len(item[0]), item[0], item[1]))[0]


def describe(path: str, verb: str, operation: dict):
    path_names = set(re.findall(r"\{([^}]+)\}", path))
    query_names = []
    for parameter in operation.get("parameters", []):
        if parameter.get("in") != "query":
            continue
        name = parameter.get("name", "")
        if name and name not in path_names:
            query_names.append(name)
    return path, verb.upper(), ",".join(query_names)

media_upload = pick("media-upload", ("post",), action="upload")
request_content = media_upload[2].get("requestBody", {}).get("content", {})
if not any(key.lower().startswith("multipart/form-data") for key in request_content):
    raise SystemExit(f"Media upload is not multipart/form-data in Swagger: {sorted(request_content)}")

selected = {
    "MEDIA_UPLOAD": describe(*media_upload),
    "LISTING_CREATE": describe(*pick("listing-command", ("post",), no_path_parameter=True)),
    "LISTING_PUBLISH": describe(*pick("listing-command", ("post",), action="publish")),
    "PHOTO_ATTACH": describe(*pick("listing-photo", ("post", "put"), action="attach")),
    "PHOTO_REORDER": describe(*pick("listing-photo", ("post", "put"), action="reorder")),
    "PUBLIC_LIST": describe(*pick("public-listing", ("get",), no_path_parameter=True)),
    "PUBLIC_PHOTO": describe(*pick("public-listing", ("get",), action="photo")),
}

with open(env_path, "w", encoding="utf-8") as handle:
    for key, (path, method, query) in selected.items():
        handle.write(f"{key}_PATH={shlex.quote(path)}\n")
        handle.write(f"{key}_METHOD={shlex.quote(method)}\n")
        handle.write(f"{key}_QUERY={shlex.quote(query)}\n")
print("LISTING PHOTO HTTP ROUTES:", selected)
PY

# shellcheck disable=SC1090
source "$ROUTES"

render_url() {
  local path="$1" query_names="$2" listing_id="${3:-}" photo_id="${4:-}"
  local rendered="$path"
  rendered="${rendered//\{listingId\}/$listing_id}"
  rendered="${rendered//\{id\}/$listing_id}"
  rendered="${rendered//\{photoId\}/$photo_id}"

  local url="$BASE$rendered"
  local separator='?'
  local name lower value
  IFS=',' read -ra names <<< "$query_names"
  for name in "${names[@]}"; do
    [[ -n "$name" ]] || continue
    lower="${name,,}"
    value=''
    case "$lower" in
      id|listingid) value="$listing_id" ;;
      photoid) value="$photo_id" ;;
      *) continue ;;
    esac
    url+="${separator}${name}=${value}"
    separator='&'
  done
  printf '%s' "$url"
}

request_json() {
  local method="$1" url="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$url"
}

get_token() {
  local username="$1" password="$2"
  local token_file="${TMPDIR:-/tmp}/bpt2-listing-photo-token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token request for $username expected 200, got $status: $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    value = json.load(handle).get("access_token")
if not value:
    raise SystemExit("Token response did not contain access_token")
print(value)
PY
}

upload_image() {
  local token="$1" declared_type="$2"
  curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
    --request "$MEDIA_UPLOAD_METHOD" "$BASE$MEDIA_UPLOAD_PATH" \
    -H "Authorization: Bearer $token" \
    -F "content=@${PNG};type=${declared_type}"
}

MEDIA_URL="$BASE$MEDIA_UPLOAD_PATH"
status="$(curl --silent --output /dev/null --write-out '%{http_code}' --request "$MEDIA_UPLOAD_METHOD" "$MEDIA_URL")"
[[ "$status" == "401" ]] || { echo "Anonymous media upload expected 401, got $status" >&2; exit 1; }

echo "PHOTO_UPLOAD_AUTH: PASS"

ADMIN_TOKEN="$(get_token admin '1q2w3E*')"
SELLER_B_USER="seller-photo-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:12])
PY
)"
SELLER_B_PASSWORD='Bpt2-PhotoSeller-9!x'
SELLER_B_EMAIL="${SELLER_B_USER}@example.invalid"
SELLER_B_BODY="$(python3 - "$SELLER_B_USER" "$SELLER_B_EMAIL" "$SELLER_B_PASSWORD" <<'PY'
import json, sys
username, email, password = sys.argv[1:]
print(json.dumps({
    "userName": username,
    "name": "Photo",
    "surname": "Seller",
    "email": email,
    "password": password,
    "isActive": True,
    "lockoutEnabled": True,
    "roleNames": []
}))
PY
)"
status="$(request_json POST "$BASE/api/identity/users" "$ADMIN_TOKEN" "$SELLER_B_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Identity user create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
SELLER_B_TOKEN="$(get_token "$SELLER_B_USER" "$SELLER_B_PASSWORD")"

# Bytes say PNG while multipart metadata says JPEG: must be rejected.
status="$(upload_image "$ADMIN_TOKEN" 'image/jpeg')"
[[ "$status" == "400" ]] || { echo "Mismatched image type expected 400, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "PHOTO_BYTE_TYPE_VALIDATION: PASS"

status="$(upload_image "$ADMIN_TOKEN" 'image/png')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Media upload expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_1="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
for forbidden in ("storageKey", "provider", "storageProvider"):
    if forbidden in data:
        raise SystemExit(f"Upload response leaked storage internals: {data}")
if data.get("contentType") != "image/png":
    raise SystemExit(f"Detected contentType was not image/png: {data}")
print(data["id"])
PY
)"

status="$(upload_image "$ADMIN_TOKEN" 'image/png')"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Second media upload expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_2="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["id"])
PY
)"
[[ "$MEDIA_1" != "$MEDIA_2" ]] || { echo "Distinct uploads returned the same MediaAssetId" >&2; exit 1; }
echo "PHOTO_MEDIA_ASSET: PASS"

CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1],
    "title": "HTTP Listing With Photos",
    "price": 135000,
    "description": "Listing exercising the real Media/ListingPhoto HTTP slice.",
    "manufactureYear": 2024,
    "mileageKm": 7000,
    "color": "Azul",
    "city": "Porto Alegre",
    "stateCode": "RS"
}))
PY
)"
status="$(request_json "$LISTING_CREATE_METHOD" "$BASE$LISTING_CREATE_PATH" "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("status") != "Draft":
    raise SystemExit(f"Photo slice Listing was not Draft: {data}")
print(data["id"])
PY
)"

ATTACH_URL="$(render_url "$PHOTO_ATTACH_PATH" "$PHOTO_ATTACH_QUERY" "$LISTING_ID")"
ATTACH_1_BODY="$(python3 - "$MEDIA_1" <<'PY'
import json, sys
print(json.dumps({"mediaAssetId": sys.argv[1]}))
PY
)"
status="$(request_json "$PHOTO_ATTACH_METHOD" "$ATTACH_URL" "$SELLER_B_TOKEN" "$ATTACH_1_BODY")"
[[ "$status" == "403" ]] || { echo "Cross-seller photo attach expected 403, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
echo "PHOTO_OWNERSHIP: PASS"

status="$(request_json "$PHOTO_ATTACH_METHOD" "$ATTACH_URL" "$ADMIN_TOKEN" "$ATTACH_1_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Owner photo attach expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_1="$(python3 - "$RESPONSE" "$MEDIA_1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
media_id = sys.argv[2].lower()
match = next((item for item in data if str(item.get("mediaAssetId", "")).lower() == media_id), None)
if match is None:
    raise SystemExit(f"Attached MediaAssetId missing from ListingPhoto response: {data}")
print(match["id"])
PY
)"

ATTACH_2_BODY="$(python3 - "$MEDIA_2" <<'PY'
import json, sys
print(json.dumps({"mediaAssetId": sys.argv[1]}))
PY
)"
status="$(request_json "$PHOTO_ATTACH_METHOD" "$ATTACH_URL" "$ADMIN_TOKEN" "$ATTACH_2_BODY")"
[[ "$status" == "200" || "$status" == "201" ]] || { echo "Second owner photo attach expected 200/201, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_2="$(python3 - "$RESPONSE" "$MEDIA_2" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
media_id = sys.argv[2].lower()
match = next((item for item in data if str(item.get("mediaAssetId", "")).lower() == media_id), None)
if match is None:
    raise SystemExit(f"Second MediaAssetId missing from ListingPhoto response: {data}")
print(match["id"])
PY
)"

REORDER_URL="$(render_url "$PHOTO_REORDER_PATH" "$PHOTO_REORDER_QUERY" "$LISTING_ID")"
REORDER_BODY="$(python3 - "$PHOTO_2" "$PHOTO_1" <<'PY'
import json, sys
print(json.dumps({"photoIds": [sys.argv[1], sys.argv[2]]}))
PY
)"
status="$(request_json "$PHOTO_REORDER_METHOD" "$REORDER_URL" "$ADMIN_TOKEN" "$REORDER_BODY")"
[[ "$status" == "200" ]] || { echo "Photo reorder expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$PHOTO_2" "$PHOTO_1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    photos = json.load(handle)
expected = [sys.argv[2].lower(), sys.argv[3].lower()]
actual = [str(item.get("id", "")).lower() for item in photos]
orders = [item.get("sortOrder") for item in photos]
if actual != expected or orders != [0, 1]:
    raise SystemExit(f"Photo reorder/cover semantics mismatch: photos={photos}")
PY
echo "PHOTO_ORDER_AND_COVER: PASS"

# A Draft listing must not make photo bytes public.
PUBLIC_PHOTO_URL="$(render_url "$PUBLIC_PHOTO_PATH" "$PUBLIC_PHOTO_QUERY" "$LISTING_ID" "$PHOTO_2")"
status="$(curl --silent --show-error --output "$PHOTO_RESPONSE" --write-out '%{http_code}' "$PUBLIC_PHOTO_URL")"
[[ "$status" == "404" ]] || { echo "Draft Listing public photo expected 404, got $status" >&2; exit 1; }

PUBLISH_URL="$(render_url "$LISTING_PUBLISH_PATH" "$LISTING_PUBLISH_QUERY" "$LISTING_ID")"
status="$(request_json "$LISTING_PUBLISH_METHOD" "$PUBLISH_URL" "$ADMIN_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner publish expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }

status="$(request_json "$PUBLIC_LIST_METHOD" "$BASE$PUBLIC_LIST_PATH")"
[[ "$status" == "200" ]] || { echo "Public Listing list expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" "$PHOTO_2" "$PHOTO_1" "$MEDIA_2" "$MEDIA_1" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    root = json.load(handle)
listing_id, photo2, photo1, media2, media1 = [value.lower() for value in sys.argv[2:]]

def walk(value):
    if isinstance(value, dict):
        if str(value.get("id", "")).lower() == listing_id and "photos" in value:
            return value
        for child in value.values():
            found = walk(child)
            if found is not None:
                return found
    elif isinstance(value, list):
        for child in value:
            found = walk(child)
            if found is not None:
                return found
    return None

listing = walk(root)
if listing is None:
    raise SystemExit(f"Published Listing missing from public projection: {root}")
serialized = json.dumps(listing).lower()
for forbidden in ("storagekey", "storageprovider", "blobkey", "providername"):
    if forbidden in serialized:
        raise SystemExit(f"Public projection leaked storage internals ({forbidden}): {listing}")
photos = listing.get("photos", [])
actual_photo_ids = [str(item.get("id", "")).lower() for item in photos]
actual_media_ids = [str(item.get("mediaAssetId", "")).lower() for item in photos]
orders = [item.get("sortOrder") for item in photos]
if actual_photo_ids != [photo2, photo1] or actual_media_ids != [media2, media1] or orders != [0, 1]:
    raise SystemExit(f"Public photo projection/order mismatch: {photos}")
PY
echo "PHOTO_PUBLIC_PROJECTION: PASS"

status="$(curl --silent --show-error --dump-header "$PHOTO_HEADERS" --output "$PHOTO_RESPONSE" --write-out '%{http_code}' "$PUBLIC_PHOTO_URL")"
[[ "$status" == "200" ]] || { echo "Published public photo content expected 200, got $status" >&2; exit 1; }
cmp -s "$PNG" "$PHOTO_RESPONSE" || { echo "Public photo content bytes differ from uploaded bytes" >&2; exit 1; }
grep -qi '^content-type: image/png' "$PHOTO_HEADERS" || { echo "Public photo content type was not image/png" >&2; cat "$PHOTO_HEADERS" >&2; exit 1; }
echo "PHOTO_PUBLIC_CONTENT: PASS"

echo "LISTING PHOTO HTTP: PASSED"
