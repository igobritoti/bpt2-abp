#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_AUTH_LEAD_API_PORT:-5104}"
BASE="http://127.0.0.1:${PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-authenticated-lead"
LOG="$TMP/api.log"; RESPONSE="$TMP/response.json"; TOKEN_FILE="$TMP/token.json"; PNG="$TMP/photo.png"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false BPT_MEDIA_ROOT="$TMP/media"
API_PID=""; cleanup(){ [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$BASE/swagger/v1/swagger.json" >/dev/null || { cat "$LOG" >&2; exit 1; }

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
token(){ local username="$1" password="$2"; curl --silent --show-error -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$username" --data-urlencode "password=$password" --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }

ADMIN_TOKEN="$(token admin '1q2w3E*')"
status="$(request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Authenticated Lead Fixture","whatsAppNumber":"5511999997766"}')"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' -X POST "$BASE/api/app/media-upload/upload" -H "Authorization: Bearer $ADMIN_TOKEN" -F "content=@${PNG};type=image/png")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
MEDIA_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Authenticated Lead Fixture','price':151000,'description':'Authenticated Lead proof','manufactureYear':2024,'mileageKm':7000,'color':'Azul','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"
ATTACH_BODY="$(python3 - "$MEDIA_ID" <<'PY'
import json,sys; print(json.dumps({'mediaAssetId':sys.argv[1]}))
PY
)"
status="$(request POST "/api/app/listing-photo/attach/$LISTING_ID" "$ADMIN_TOKEN" "$ATTACH_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }

BUYER="auth-lead-$(python3 -c 'import uuid; print(uuid.uuid4().hex[:10])')"
BUYER_EMAIL="${BUYER}@example.invalid"
BUYER_PASSWORD='Bpt2-AuthLead-9!x'
REGISTER_BODY="$(python3 - "$BUYER" "$BUYER_EMAIL" "$BUYER_PASSWORD" <<'PY'
import json,sys
print(json.dumps({'userName':sys.argv[1],'emailAddress':sys.argv[2],'password':sys.argv[3],'appName':'BomPraTi'}))
PY
)"
status="$(request POST '/api/account/register' '' "$REGISTER_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Self-registration failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
BUYER_ID="$(python3 - "$RESPONSE" "$BUYER" <<'PY'
import json,sys
data=json.load(open(sys.argv[1])); assert data.get('userName')==sys.argv[2],data; assert data.get('id'),data; print(data['id'])
PY
)"
echo 'AUTHENTICATED_LEAD_SELF_REGISTRATION: PASS'
BUYER_TOKEN="$(token "$BUYER" "$BUYER_PASSWORD")"
[[ -n "$BUYER_TOKEN" ]] || exit 1
echo 'AUTHENTICATED_LEAD_TOKEN: PASS'

status="$(request POST "/api/app/lead?listingId=$LISTING_ID" "$BUYER_TOKEN")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Authenticated Lead expected 200/201 got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$LISTING_ID" "$BUYER_ID" <<'PY'
import json,sys
data=json.load(open(sys.argv[1]))
assert str(data.get('listingId','')).lower()==sys.argv[2].lower(),data
assert str(data.get('userId','')).lower()==sys.argv[3].lower(),data
assert data.get('channel')=='WhatsApp',data
assert data.get('id') and data.get('createdAtUtc'),data
PY
echo 'AUTHENTICATED_LEAD_USER_ID: PASS'
echo 'AUTHENTICATED LEAD HTTP: PASSED'
