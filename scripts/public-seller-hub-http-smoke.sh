#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_API_PORT:-5104}"
WEB_PORT="${BPT_PUBLIC_SELLER_WEB_PORT:-3104}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-seller-hub"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
RESPONSE="$TMP/response.json"
DETAIL_HTML="$TMP/detail.html"
SELLER_HTML="$TMP/seller.html"
PNG="$TMP/seller-hub.png"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"

rm -rf "$TMP"
mkdir -p "$TMP"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false
export BPT_MEDIA_ROOT="$TMP/media"
mkdir -p "$BPT_MEDIA_ROOT"

API_PID=""
WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" path="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  curl "${args[@]}" "$API_BASE$path"
}

get_token() {
  local username="$1" password="$2"
  local token_file="$TMP/token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' \
    -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode "username=$username" \
    --data-urlencode "password=$password" \
    --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == "200" ]] || { echo "Token request for $username failed: $status $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    token = json.load(handle).get("access_token")
if not token:
    raise SystemExit("Token response missing access_token")
print(token)
PY
}

create_user() {
  local admin_token="$1" username="$2" email="$3" password="$4" name="$5"
  local body status
  body="$(python3 - "$username" "$email" "$password" "$name" <<'PY'
import json, sys
username, email, password, name = sys.argv[1:]
print(json.dumps({
    "userName": username, "name": name, "surname": "Seller", "email": email,
    "password": password, "isActive": True, "lockoutEnabled": True, "roleNames": []
}))
PY
)"
  status="$(request_json POST '/api/identity/users' "$admin_token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Identity user create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
}

upsert_profile() {
  local token="$1" display_name="$2" whatsapp="$3"
  local body status
  body="$(python3 - "$display_name" "$whatsapp" <<'PY'
import json, sys
print(json.dumps({"displayName": sys.argv[1], "whatsAppNumber": sys.argv[2]}))
PY
)"
  status="$(request_json POST '/api/app/seller-profile/upsert' "$token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Seller profile upsert failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data = json.load(handle)
print(data["id"])
PY
}

create_listing() {
  local token="$1" title="$2" price="$3"
  local body status
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" <<'PY'
import json, sys
print(json.dumps({
    "vehicleId": sys.argv[1], "title": sys.argv[2], "price": float(sys.argv[3]),
    "description": "Fixture do Public Seller Hub.", "manufactureYear": 2024,
    "mileageKm": 9000, "color": "Prata", "city": "São Paulo", "stateCode": "SP"
}))
PY
)"
  status="$(request_json POST '/api/app/listing-command' "$token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Listing create failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle: data = json.load(handle)
if data.get("status") != "Draft": raise SystemExit(f"Listing must start Draft: {data}")
print(data["id"])
PY
}

attach_photo() {
  local token="$1" listing_id="$2" media_id status body
  status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
    -X POST "$API_BASE/api/app/media-upload/upload" -H "Authorization: Bearer $token" \
    -F "content=@${PNG};type=image/png")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Media upload failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  media_id="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"
  body="$(python3 - "$media_id" <<'PY'
import json,sys
print(json.dumps({'mediaAssetId':sys.argv[1]}))
PY
)"
  status="$(request_json POST "/api/app/listing-photo/attach/$listing_id" "$token" "$body")"
  [[ "$status" == "200" || "$status" == "201" ]] || { echo "Photo attach failed: $status $(cat "$RESPONSE")" >&2; return 1; }
  python3 - "$RESPONSE" "$media_id" <<'PY'
import json,sys
photos=json.load(open(sys.argv[1], encoding='utf-8')); media=sys.argv[2].lower()
photo=next((x for x in photos if str(x.get('mediaAssetId','')).lower()==media),None)
if not photo: raise SystemExit(f'Attached photo missing: {photos}')
print(photo['id'])
PY
}

publish_listing() {
  local token="$1" listing_id="$2" status
  status="$(request_json POST "/api/app/listing-command/publish/$listing_id" "$token")"
  [[ "$status" == "200" ]] || { echo "Listing publish failed: $status $(cat "$RESPONSE")" >&2; return 1; }
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null && break
  if ! kill -0 "$API_PID" >/dev/null 2>&1; then cat "$API_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(get_token admin '1q2w3E*')"
SUFFIX="$(python3 -c 'import uuid; print(uuid.uuid4().hex[:10])')"
OWNER_USER="seller-hub-owner-$SUFFIX"; OTHER_USER="seller-hub-other-$SUFFIX"
OWNER_PASSWORD='Bpt2-SellerHub-Owner-9!x'; OTHER_PASSWORD='Bpt2-SellerHub-Other-9!x'
OWNER_NAME="Seller Hub Owner $SUFFIX"; OTHER_NAME="Seller Hub Other $SUFFIX"
create_user "$ADMIN_TOKEN" "$OWNER_USER" "$OWNER_USER@example.invalid" "$OWNER_PASSWORD" "HubOwner"
create_user "$ADMIN_TOKEN" "$OTHER_USER" "$OTHER_USER@example.invalid" "$OTHER_PASSWORD" "HubOther"
OWNER_TOKEN="$(get_token "$OWNER_USER" "$OWNER_PASSWORD")"; OTHER_TOKEN="$(get_token "$OTHER_USER" "$OTHER_PASSWORD")"
OWNER_ID="$(upsert_profile "$OWNER_TOKEN" "$OWNER_NAME" '+55 (11) 95555-1101')"
OTHER_ID="$(upsert_profile "$OTHER_TOKEN" "$OTHER_NAME" '+55 (11) 95555-2202')"
[[ "$OWNER_ID" != "$OTHER_ID" ]] || { echo "Seller fixture ids must differ" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_SELLERS: PASS"

OWNER_TITLE="Seller Hub Public $SUFFIX"; OWNER_DRAFT_TITLE="Seller Hub Draft $SUFFIX"; OTHER_TITLE="Seller Hub Other Public $SUFFIX"
OWNER_LISTING_ID="$(create_listing "$OWNER_TOKEN" "$OWNER_TITLE" 135000)"
OWNER_DRAFT_ID="$(create_listing "$OWNER_TOKEN" "$OWNER_DRAFT_TITLE" 136000)"
OTHER_LISTING_ID="$(create_listing "$OTHER_TOKEN" "$OTHER_TITLE" 145000)"
OWNER_PHOTO_ID="$(attach_photo "$OWNER_TOKEN" "$OWNER_LISTING_ID")"
publish_listing "$OWNER_TOKEN" "$OWNER_LISTING_ID"
publish_listing "$OTHER_TOKEN" "$OTHER_LISTING_ID"
echo "PUBLIC_SELLER_HUB_FIXTURES: PASS"

status="$(request_json GET "/api/app/public-listing?SellerId=$OWNER_ID&Take=24")"
[[ "$status" == "200" ]] || { echo "SellerId public query expected 200, got $status: $(cat "$RESPONSE")" >&2; exit 1; }
python3 - "$RESPONSE" "$OWNER_ID" "$OWNER_LISTING_ID" "$OWNER_DRAFT_ID" "$OTHER_LISTING_ID" <<'PY'
import json, sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
owner_id, owner_listing_id, owner_draft_id, other_listing_id=(v.lower() for v in sys.argv[2:6])
items=data.get('items') or []; ids={str(x.get('id','')).lower() for x in items}
if data.get('totalCount') != 1 or ids != {owner_listing_id}: raise SystemExit(f'Seller filter mismatch: {data}')
if str((items[0].get('seller') or {}).get('sellerId','')).lower() != owner_id: raise SystemExit(f'Seller projection mismatch: {data}')
if owner_draft_id in ids or other_listing_id in ids: raise SystemExit(f'Seller filter leaked fixture: {data}')
PY
echo "PUBLIC_SELLER_HUB_API_FILTER: PASS"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do
  curl --fail --silent --show-error "$WEB_BASE" >/dev/null && break
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then cat "$WEB_LOG" >&2; exit 1; fi
  sleep 1
done
curl --fail --silent --show-error "$WEB_BASE" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$OWNER_LISTING_ID")"
[[ "$status" == "200" ]] || { echo "Owner detail expected 200, got $status" >&2; exit 1; }
grep -Fq "$OWNER_NAME" "$DETAIL_HTML" || { echo "Owner display name missing from detail" >&2; exit 1; }
grep -Fq "/vendedores/$OWNER_ID" "$DETAIL_HTML" || { echo "Seller Hub link missing from detail" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_DETAIL_LINK: PASS"

assert_seller_metadata() {
  local file="$1" name="$2" canonical="$3" image="${4:-}"
  python3 - "$file" "$name" "$canonical" "$image" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    def __init__(self): super().__init__(); self.meta=[]; self.title=[]; self.in_title=False; self.canonical=None
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=='title': self.in_title=True
        elif tag=='meta': self.meta.append(a)
        elif tag=='link' and a.get('rel')=='canonical': self.canonical=a.get('href')
    def handle_endtag(self,tag):
        if tag=='title': self.in_title=False
    def handle_data(self,data):
        if self.in_title: self.title.append(data)
p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read())
name,canonical,image=sys.argv[2:5]; title=''.join(p.title).strip(); desc=f'1 anúncio(s) público(s) de {name} no Bom Pra Ti.'
if title != f'{name} | Bom Pra Ti' or p.canonical != canonical: raise SystemExit(f'Base metadata mismatch: {title!r} {p.canonical!r}')
values={}
for a in p.meta:
    k=a.get('property') or a.get('name')
    if k: values.setdefault(k,[]).append(a.get('content',''))
def req(k,v):
    if v not in values.get(k,[]): raise SystemExit(f'Missing {k}={v!r}; got {values.get(k)!r}')
for k,v in [('description',desc),('og:type','website'),('og:title',name),('og:description',desc),('og:url',canonical),('twitter:title',name),('twitter:description',desc)]: req(k,v)
if image:
    req('og:image',image); req('twitter:image',image); req('twitter:card','summary_large_image')
else:
    req('twitter:card','summary')
    if values.get('og:image') or values.get('twitter:image'): raise SystemExit(f'No-photo Seller Hub invented image: {values!r}')
PY
}

status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$OWNER_ID")"
[[ "$status" == "200" ]] || { echo "Seller Hub expected 200, got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }
grep -Fq "$OWNER_NAME" "$SELLER_HTML" || { echo "Seller Hub display name missing" >&2; exit 1; }
grep -Fq "$OWNER_TITLE" "$SELLER_HTML" || { echo "Seller Hub owner Listing missing" >&2; exit 1; }
grep -Fq "/anuncios/$OWNER_LISTING_ID" "$SELLER_HTML" || { echo "Seller Hub Listing link missing" >&2; exit 1; }
if grep -Fq "$OWNER_DRAFT_TITLE" "$SELLER_HTML"; then echo "Seller Hub leaked owner Draft" >&2; exit 1; fi
if grep -Fq "$OTHER_TITLE" "$SELLER_HTML"; then echo "Seller Hub leaked other Seller Listing" >&2; exit 1; fi
OWNER_IMAGE="$API_BASE/api/app/public-listing/$OWNER_LISTING_ID/photo/$OWNER_PHOTO_ID"
assert_seller_metadata "$SELLER_HTML" "$OWNER_NAME" "$WEB_BASE/vendedores/$OWNER_ID" "$OWNER_IMAGE"
echo "PUBLIC_SELLER_HUB_SHARE_METADATA: PASS"
echo "PUBLIC_SELLER_HUB_SOCIAL_IMAGE: PASS"
echo "PUBLIC_SELLER_HUB_VISIBLE: PASS"
echo "PUBLIC_SELLER_HUB_ISOLATED: PASS"

status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$OTHER_ID")"
[[ "$status" == "200" ]] || { echo "No-photo Seller Hub expected 200, got $status" >&2; exit 1; }
assert_seller_metadata "$SELLER_HTML" "$OTHER_NAME" "$WEB_BASE/vendedores/$OTHER_ID"
echo "PUBLIC_SELLER_HUB_SHARE_METADATA_NO_IMAGE: PASS"

UNKNOWN_ID="00000000-0000-4000-8000-000000000001"
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$UNKNOWN_ID")"
[[ "$status" == "404" ]] || { echo "Unknown Seller Hub expected 404, got $status" >&2; exit 1; }
if grep -Fq 'property="og:url"' "$SELLER_HTML"; then echo "Unknown Seller Hub leaked og:url" >&2; exit 1; fi
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/not-a-guid")"
[[ "$status" == "404" ]] || { echo "Invalid Seller Hub id expected 404, got $status" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_SHARE_METADATA_UNKNOWN_404: PASS"
echo "PUBLIC_SELLER_HUB_UNKNOWN_HIDDEN: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$OWNER_LISTING_ID" "$OWNER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Owner Listing pause failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request_json GET "/api/app/public-listing?SellerId=$OWNER_ID&Take=24")"
[[ "$status" == "200" ]] || { echo "Paused SellerId public query expected 200, got $status" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
data=json.load(open(sys.argv[1], encoding='utf-8'))
if data.get('totalCount') != 0 or data.get('items') not in ([],None): raise SystemExit(f'Paused Seller must have no public Listings: {data}')
PY
status="$(curl --silent --show-error --output "$SELLER_HTML" --write-out '%{http_code}' "$WEB_BASE/vendedores/$OWNER_ID")"
[[ "$status" == "404" ]] || { echo "Seller Hub without public Listing expected 404, got $status" >&2; exit 1; }
if grep -Fq 'property="og:url"' "$SELLER_HTML"; then echo "Empty Seller Hub leaked og:url" >&2; exit 1; fi
echo "PUBLIC_SELLER_HUB_SHARE_METADATA_EMPTY_404: PASS"
echo "PUBLIC_SELLER_HUB_EMPTY_HIDDEN: PASS"

status="$(request_json POST "/api/app/listing-command/pause/$OTHER_LISTING_ID" "$OTHER_TOKEN")"
[[ "$status" == "200" ]] || { echo "Other Seller Listing cleanup failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
echo "PUBLIC_SELLER_HUB_FIXTURES_CLEANED: PASS"
echo "PUBLIC SELLER HUB HTTP: PASSED"
