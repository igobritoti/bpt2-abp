#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_VEHICLE_HUB_API_PORT:-5097}"
WEB_PORT="${BPT_VEHICLE_HUB_WEB_PORT:-3097}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-vehicle-hub"
RESPONSE="$TMP/response.json"
VEHICLE_JSON="$TMP/vehicle.json"
API_LOG="$TMP/api.log"
WEB_LOG="$TMP/web.log"
HUB_HTML="$TMP/hub.html"
DETAIL_HTML="$TMP/detail.html"
PNG="$TMP/vehicle-hub.png"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"
printf '%s' 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=' | base64 --decode > "$PNG"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false
export BPT_MEDIA_ROOT="$TMP/media"
mkdir -p "$BPT_MEDIA_ROOT"

API_PID=""; WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

request_json() {
  local method="$1" url="$2" token="${3:-}" body="${4:-}"
  local args=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method")
  [[ -z "$token" ]] || args+=(-H "Authorization: Bearer $token")
  [[ -z "$body" ]] || args+=(-H 'Content-Type: application/json' --data "$body")
  curl "${args[@]}" "$url"
}

token() {
  curl --silent --show-error -X POST "$API_BASE/connect/token" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode 'grant_type=password' \
    --data-urlencode 'client_id=BomPraTi_App' \
    --data-urlencode 'username=admin' \
    --data-urlencode 'password=1q2w3E*' \
    --data-urlencode 'scope=BomPraTi' \
    | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
}

assert_social_image_state() {
  local file="$1" expected_image="${2:-}"
  python3 - "$file" "$expected_image" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
    def __init__(self): super().__init__(); self.meta=[]
    def handle_starttag(self,tag,attrs):
        if tag=='meta': self.meta.append(dict(attrs))
p=P(); p.feed(open(sys.argv[1], encoding='utf-8').read())
expected=sys.argv[2]
def meta(key,value):
    for item in p.meta:
        if item.get(key)==value: return item.get('content')
    return None
og=meta('property','og:image'); tw=meta('name','twitter:image'); card=meta('name','twitter:card')
if expected:
    if og != expected or tw != expected or card != 'summary_large_image':
        raise SystemExit(f'Vehicle Hub social image mismatch: og={og!r} tw={tw!r} card={card!r}')
else:
    if og is not None or tw is not None or card != 'summary':
        raise SystemExit(f'Vehicle Hub no-image fallback mismatch: og={og!r} tw={tw!r} card={card!r}')
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }

ADMIN_TOKEN="$(token)"
status="$(request_json POST "$API_BASE/api/app/seller-profile/upsert" "$ADMIN_TOKEN" '{"displayName":"Vehicle Hub Seller","whatsAppNumber":"+55 (11) 98888-7766"}')"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Seller upsert failed $status: $(cat "$RESPONSE")" >&2; exit 1; }

LISTING_TITLE="Vehicle Hub HTTP Listing"
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$LISTING_TITLE" <<'PY'
import json,sys
print(json.dumps({
  'vehicleId':sys.argv[1], 'title':sys.argv[2], 'price':135900,
  'description':'Oferta usada para provar o Vehicle Hub público.',
  'manufactureYear':2024, 'mileageKm':18000, 'color':'Prata',
  'city':'Campinas', 'stateCode':'SP'
}))
PY
)"
status="$(request_json POST "$API_BASE/api/app/listing-command" "$ADMIN_TOKEN" "$CREATE_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Listing create failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1], encoding='utf-8')); assert x['status']=='Draft',x; print(x['id'])
PY
)"

status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
  -X POST "$API_BASE/api/app/media-upload/upload" -H "Authorization: Bearer $ADMIN_TOKEN" \
  -F "content=@${PNG};type=image/png")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Media upload failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
MEDIA_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1], encoding='utf-8'))['id'])
PY
)"
ATTACH_BODY="$(python3 - "$MEDIA_ID" <<'PY'
import json,sys
print(json.dumps({'mediaAssetId':sys.argv[1]}))
PY
)"
status="$(request_json POST "$API_BASE/api/app/listing-photo/attach/$LISTING_ID" "$ADMIN_TOKEN" "$ATTACH_BODY")"
[[ "$status" == 200 || "$status" == 201 ]] || { echo "Photo attach failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
PHOTO_ID="$(python3 - "$RESPONSE" "$MEDIA_ID" <<'PY'
import json,sys
photos=json.load(open(sys.argv[1], encoding='utf-8')); media=sys.argv[2].lower()
photo=next((x for x in photos if str(x.get('mediaAssetId','')).lower()==media),None)
if not photo: raise SystemExit(f'Attached photo missing: {photos}')
print(photo['id'])
PY
)"
SOCIAL_IMAGE="$API_BASE/api/app/public-listing/$LISTING_ID/photo/$PHOTO_ID"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do curl --fail --silent "$WEB_BASE" >/dev/null && break; sleep 1; done
curl --fail --silent "$WEB_BASE" >/dev/null || { cat "$WEB_LOG" >&2; exit 1; }

UNKNOWN_VEHICLE="$(python3 -c 'import uuid; print(uuid.uuid4())')"
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$UNKNOWN_VEHICLE")"
[[ "$status" == 404 ]] || { echo "Unknown Vehicle Hub expected 404 got $status" >&2; exit 1; }
grep -Fq 'noindex' "$HUB_HTML" || { echo 'Unknown Vehicle Hub is missing noindex metadata' >&2; exit 1; }
if grep -Fq "property=\"og:url\" content=\"$WEB_BASE/veiculos/$UNKNOWN_VEHICLE\"" "$HUB_HTML"; then echo 'Unknown Vehicle Hub leaked social URL metadata' >&2; exit 1; fi
if grep -Fq 'application/ld+json' "$HUB_HTML"; then echo 'Unknown Vehicle Hub leaked structured data' >&2; exit 1; fi
echo 'VEHICLE_HUB_UNKNOWN_404: PASS'
echo 'VEHICLE_HUB_UNKNOWN_NOINDEX: PASS'
echo 'VEHICLE_HUB_SHARE_METADATA_UNKNOWN_404: PASS'
echo 'VEHICLE_HUB_STRUCTURED_DATA_UNKNOWN_EXCLUDED: PASS'

status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Canonical Vehicle Hub expected 200 got $status" >&2; cat "$WEB_LOG" >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Model' "$HUB_HTML" || { echo 'Canonical model missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP-G1' "$HUB_HTML" || { echo 'Canonical generation missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Version' "$HUB_HTML" || { echo 'Canonical version missing from Hub' >&2; exit 1; }
grep -Fq '>2025<' "$HUB_HTML" || { echo 'Canonical model year missing from Hub' >&2; exit 1; }
grep -Fq 'HTTP Lifecycle Model HTTP Lifecycle Version 2025 | Bom Pra Ti</title>' "$HUB_HTML" || { echo 'Vehicle Hub metadata title missing' >&2; exit 1; }
grep -Fq "rel=\"canonical\" href=\"$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID\"" "$HUB_HTML" || { echo 'Vehicle Hub canonical missing' >&2; exit 1; }
assert_social_image_state "$HUB_HTML"
status="$(request_json GET "$API_BASE/api/app/vehicle-catalog/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Canonical Vehicle API expected 200 got $status" >&2; cat "$RESPONSE" >&2; exit 1; }
cp "$RESPONSE" "$VEHICLE_JSON"
python3 - "$HUB_HTML" "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID" "$VEHICLE_JSON" <<'PY'
from html.parser import HTMLParser
import json,sys
class MetaParser(HTMLParser):
    def __init__(self):
        super().__init__(); self.meta=[]; self.links=[]; self.title_parts=[]; self.in_title=False; self.in_json_ld=False; self.current_json_ld=[]; self.json_ld=[]
    def handle_starttag(self,tag,attrs):
        v=dict(attrs)
        if tag=='meta': self.meta.append(v)
        elif tag=='link': self.links.append(v)
        elif tag=='title': self.in_title=True
        elif tag=='script' and v.get('type')=='application/ld+json': self.in_json_ld=True; self.current_json_ld=[]
    def handle_endtag(self,tag):
        if tag=='title': self.in_title=False
        elif tag=='script' and self.in_json_ld: self.json_ld.append(''.join(self.current_json_ld)); self.in_json_ld=False; self.current_json_ld=[]
    def handle_data(self,data):
        if self.in_title: self.title_parts.append(data)
        if self.in_json_ld: self.current_json_ld.append(data)
p=MetaParser(); p.feed(open(sys.argv[1], encoding='utf-8').read())
def meta(k,v):
    for x in p.meta:
        if x.get(k)==v: return x.get('content')
    return None
canonical=sys.argv[2]; vehicle=json.load(open(sys.argv[3], encoding='utf-8')); rendered=''.join(p.title_parts).strip(); suffix=' | Bom Pra Ti'
if not rendered.endswith(suffix): raise SystemExit(f'Vehicle Hub title malformed: {rendered!r}')
title=rendered[:-len(suffix)]; desc=meta('name','description')
if not desc or meta('property','og:title')!=title or meta('property','og:description')!=desc or meta('property','og:url')!=canonical: raise SystemExit('Vehicle Hub base social metadata mismatch')
if meta('name','twitter:title')!=title or meta('name','twitter:description')!=desc: raise SystemExit('Vehicle Hub Twitter text metadata mismatch')
canonical_link=next((x.get('href') for x in p.links if x.get('rel')=='canonical'),None)
if canonical_link!=canonical: raise SystemExit(f'Vehicle Hub canonical mismatch: {canonical_link!r}')
if len(p.json_ld)!=1: raise SystemExit(f'Expected exactly one JSON-LD block, got {len(p.json_ld)}')
data=json.loads(p.json_ld[0]); expected_name=' '.join(x.strip() for x in [vehicle['brand'],vehicle['model'],vehicle['version']] if x and x.strip())
expected={'@context':'https://schema.org','@type':'Vehicle','name':expected_name,'url':canonical,'brand':{'@type':'Brand','name':vehicle['brand']},'model':vehicle['model'],'vehicleConfiguration':vehicle['version']}
for k,v in expected.items():
    if data.get(k)!=v: raise SystemExit(f'Vehicle Hub JSON-LD {k} mismatch: {data.get(k)!r}')
for k in ('offers','itemCondition','vehicleIdentificationNumber','aggregateRating','review','sku','mpn','image','modelDate','vehicleModelDate','productionDate','releaseDate'):
    if k in data: raise SystemExit(f'Vehicle Hub JSON-LD invented unsupported field: {k}')
PY
if grep -Fq "$LISTING_TITLE" "$HUB_HTML"; then echo 'Draft Listing leaked into Vehicle Hub' >&2; exit 1; fi
echo 'VEHICLE_HUB_CANONICAL_IDENTITY: PASS'
echo 'VEHICLE_HUB_METADATA: PASS'
echo 'VEHICLE_HUB_SHARE_METADATA_NO_IMAGE: PASS'
echo 'VEHICLE_HUB_STRUCTURED_DATA: PASS'
echo 'VEHICLE_HUB_STRUCTURED_DATA_NO_INVENTED_FIELDS: PASS'
echo 'VEHICLE_HUB_DRAFT_PRIVATE: PASS'

status="$(request_json POST "$API_BASE/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing publish failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || exit 1
grep -Fq "$LISTING_TITLE" "$HUB_HTML" || { echo 'Published Listing missing from Vehicle Hub' >&2; exit 1; }
grep -Fq "/anuncios/$LISTING_ID" "$HUB_HTML" || { echo 'Published Listing detail link missing from Vehicle Hub' >&2; exit 1; }
[[ "$(grep -Fc 'application/ld+json' "$HUB_HTML")" == "1" ]] || { echo 'Vehicle Hub structured data changed after publish' >&2; exit 1; }
assert_social_image_state "$HUB_HTML" "$SOCIAL_IMAGE"
echo 'VEHICLE_HUB_PUBLISHED_VISIBLE: PASS'
echo 'VEHICLE_HUB_SOCIAL_IMAGE: PASS'
echo 'VEHICLE_HUB_STRUCTURED_DATA_WITH_OFFER: PASS'

status="$(curl --silent --show-error --output "$DETAIL_HTML" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"
[[ "$status" == 200 ]] || { echo "Listing detail expected 200 got $status" >&2; exit 1; }
grep -Fq "/veiculos/$BPT_FIXTURE_VEHICLE_ID" "$DETAIL_HTML" || { echo 'Listing detail does not link to Vehicle Hub' >&2; exit 1; }
echo 'VEHICLE_HUB_LINKED_FROM_LISTING: PASS'

status="$(request_json POST "$API_BASE/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"
[[ "$status" == 200 ]] || { echo "Listing pause failed $status: $(cat "$RESPONSE")" >&2; exit 1; }
status="$(curl --silent --show-error --output "$HUB_HTML" --write-out '%{http_code}' "$WEB_BASE/veiculos/$BPT_FIXTURE_VEHICLE_ID")"
[[ "$status" == 200 ]] || { echo "Vehicle Hub disappeared after Pause: $status" >&2; exit 1; }
if grep -Fq "$LISTING_TITLE" "$HUB_HTML"; then echo 'Paused Listing remained visible in Vehicle Hub' >&2; exit 1; fi
grep -Fq 'Nenhum anúncio publicado agora.' "$HUB_HTML" || { echo 'Vehicle Hub empty state missing after Pause' >&2; exit 1; }
[[ "$(grep -Fc 'application/ld+json' "$HUB_HTML")" == "1" ]] || { echo 'Vehicle Hub structured data disappeared after Pause' >&2; exit 1; }
assert_social_image_state "$HUB_HTML"
echo 'VEHICLE_HUB_PAUSE_REMOVES_LISTING: PASS'
echo 'VEHICLE_HUB_PERSISTS_WITHOUT_OFFER: PASS'
echo 'VEHICLE_HUB_SOCIAL_IMAGE_REMOVED_AFTER_PAUSE: PASS'
echo 'VEHICLE_HUB_STRUCTURED_DATA_PERSISTS_WITHOUT_OFFER: PASS'
echo 'PUBLIC VEHICLE HUB HTTP: PASSED'
