#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_SEO_API_PORT:-5098}"
WEB_PORT="${BPT_SEO_WEB_PORT:-3098}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-seo"
RESPONSE="$TMP/response.json"; API_LOG="$TMP/api.log"; WEB_LOG="$TMP/web.log"; ROBOTS="$TMP/robots.txt"; SITEMAP="$TMP/sitemap.xml"; DETAIL="$TMP/detail.html"; HOME_HTML="$TMP/home.html"; UTILITY="$TMP/utility.html"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$API_BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$API_BASE" AuthServer__Authority="$API_BASE"
API_PID=""; WEB_PID=""
cleanup(){ [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true; [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$API_BASE$path"; }
token(){ curl --silent -X POST "$API_BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode 'username=admin' --data-urlencode 'password=1q2w3E*' --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }
create_listing(){
  local title="$1" price="$2" body status
  body="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" "$title" "$price" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':sys.argv[2],'price':float(sys.argv[3]),'description':'Fixture para sitemap e canonical.','manufactureYear':2024,'mileageKm':5000,'color':'Prata','city':'Curitiba','stateCode':'PR'}))
PY
)"
  status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$body")"
  [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE" >&2; return 1; }
  python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['id'])
PY
}

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }
ADMIN_TOKEN="$(token)"
status="$(request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"SEO Fixture","whatsAppNumber":"5511999993333"}')"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE" >&2; exit 1; }
SELLER_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['id'])
PY
)"
LISTING_ID="$(create_listing 'SEO public listing fixture' 99000)"
SECOND_LISTING_ID="$(create_listing 'SEO second public listing fixture' 109000)"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do curl --fail --silent "$WEB_BASE/robots.txt" -o "$ROBOTS" && break; sleep 1; done
curl --fail --silent "$WEB_BASE/robots.txt" -o "$ROBOTS" || { cat "$WEB_LOG" >&2; exit 1; }
grep -Fq 'Disallow: /favoritos' "$ROBOTS" && grep -Fq 'Disallow: /vender' "$ROBOTS" && grep -Fq 'Disallow: /api/' "$ROBOTS" && grep -Fq "Sitemap: $WEB_BASE/sitemap.xml" "$ROBOTS" || { cat "$ROBOTS" >&2; exit 1; }
echo 'PUBLIC_SEO_ROBOTS: PASS'

curl --fail --silent "$WEB_BASE/" -o "$HOME_HTML"
python3 - "$HOME_HTML" "$WEB_BASE/" <<'PY'
from html.parser import HTMLParser
import sys

class HeadParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_title = False
        self.title = []
        self.meta = {}
    def handle_starttag(self, tag, attrs):
        if tag == 'title':
            self.in_title = True
        if tag == 'meta':
            data = dict(attrs)
            key = data.get('property') or data.get('name')
            if key:
                self.meta[key] = data.get('content', '')
    def handle_endtag(self, tag):
        if tag == 'title':
            self.in_title = False
    def handle_data(self, data):
        if self.in_title:
            self.title.append(data)

parser = HeadParser()
parser.feed(open(sys.argv[1], encoding='utf-8').read())
title = ''.join(parser.title).strip()
description = 'Encontre veículos e fale diretamente com o vendedor.'
expected = {
    'description': description,
    'og:type': 'website',
    'og:title': title,
    'og:description': description,
    'og:url': sys.argv[2],
    'twitter:card': 'summary',
    'twitter:title': title,
    'twitter:description': description,
}
if title != 'Bom Pra Ti':
    raise SystemExit(f'Unexpected home title: {title!r}')
for key, value in expected.items():
    actual = parser.meta.get(key)
    if actual != value:
        raise SystemExit(f'{key} mismatch: expected {value!r}, got {actual!r}')
for key in ('og:image', 'twitter:image'):
    if key in parser.meta:
        raise SystemExit(f'Unexpected social image metadata: {key}')
PY
echo 'PUBLIC_SEO_HOME_SHARE_METADATA: PASS'
echo 'PUBLIC_SEO_HOME_SHARE_METADATA_NO_IMAGE: PASS'

curl --fail --silent "$WEB_BASE/favoritos" -o "$UTILITY"
python3 - "$UTILITY" <<'PY'
from html.parser import HTMLParser
import sys

class MetaParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.keys = []
    def handle_starttag(self, tag, attrs):
        if tag != 'meta':
            return
        data = dict(attrs)
        key = data.get('property') or data.get('name')
        if key:
            self.keys.append(key)

parser = MetaParser()
parser.feed(open(sys.argv[1], encoding='utf-8').read())
leaked = [key for key in parser.keys if key.startswith('og:') or key.startswith('twitter:')]
if leaked:
    raise SystemExit(f'Home social metadata leaked to /favoritos: {leaked}')
PY
echo 'PUBLIC_SEO_HOME_SHARE_METADATA_SCOPED: PASS'

curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
grep -Fq "<loc>$WEB_BASE/</loc>" "$SITEMAP" || { cat "$SITEMAP" >&2; exit 1; }
if grep -Fq "/anuncios/$LISTING_ID" "$SITEMAP" || grep -Fq "/anuncios/$SECOND_LISTING_ID" "$SITEMAP"; then echo 'Draft Listing leaked into sitemap.' >&2; exit 1; fi
if grep -Fq "/vendedores/$SELLER_ID" "$SITEMAP"; then echo 'Draft-only Seller leaked into sitemap.' >&2; exit 1; fi
echo 'PUBLIC_SEO_DRAFT_EXCLUDED: PASS'
echo 'PUBLIC_SEO_SELLER_HUB_DRAFT_EXCLUDED: PASS'

status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
status="$(request POST "/api/app/listing-command/publish/$SECOND_LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
grep -Fq "<loc>$WEB_BASE/anuncios/$LISTING_ID</loc>" "$SITEMAP" || { cat "$SITEMAP" >&2; exit 1; }
grep -Fq "<loc>$WEB_BASE/anuncios/$SECOND_LISTING_ID</loc>" "$SITEMAP" || { cat "$SITEMAP" >&2; exit 1; }
[[ "$(grep -Fc "<loc>$WEB_BASE/vendedores/$SELLER_ID</loc>" "$SITEMAP")" == "1" ]] || { echo 'Seller Hub sitemap entry must be deduplicated.' >&2; cat "$SITEMAP" >&2; exit 1; }
echo 'PUBLIC_SEO_PUBLISHED_IN_SITEMAP: PASS'
echo 'PUBLIC_SEO_SELLER_HUB_IN_SITEMAP: PASS'
echo 'PUBLIC_SEO_SELLER_HUB_DEDUPED: PASS'

status="$(curl --silent --show-error --output "$DETAIL" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"; [[ "$status" == 200 ]] || { cat "$WEB_LOG" >&2; exit 1; }
grep -Fq "rel=\"canonical\" href=\"$WEB_BASE/anuncios/$LISTING_ID\"" "$DETAIL" || { echo 'Canonical missing.' >&2; grep -o 'canonical[^>]*' "$DETAIL" >&2 || true; exit 1; }
echo 'PUBLIC_SEO_CANONICAL: PASS'

status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
if grep -Fq "/anuncios/$LISTING_ID" "$SITEMAP"; then echo 'Paused Listing remained in sitemap.' >&2; exit 1; fi
grep -Fq "<loc>$WEB_BASE/anuncios/$SECOND_LISTING_ID</loc>" "$SITEMAP" || { echo 'Still-public second Listing disappeared from sitemap.' >&2; exit 1; }
[[ "$(grep -Fc "<loc>$WEB_BASE/vendedores/$SELLER_ID</loc>" "$SITEMAP")" == "1" ]] || { echo 'Seller Hub must remain while another public Listing exists.' >&2; exit 1; }
echo 'PUBLIC_SEO_SELLER_HUB_PERSISTS_WITH_OFFER: PASS'

status="$(request POST "/api/app/listing-command/pause/$SECOND_LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
if grep -Fq "/anuncios/$SECOND_LISTING_ID" "$SITEMAP"; then echo 'Paused second Listing remained in sitemap.' >&2; exit 1; fi
if grep -Fq "/vendedores/$SELLER_ID" "$SITEMAP"; then echo 'Seller Hub remained after last public Listing was paused.' >&2; exit 1; fi
echo 'PUBLIC_SEO_PAUSED_EXCLUDED: PASS'
echo 'PUBLIC_SEO_SELLER_HUB_LAST_OFFER_REMOVED: PASS'
echo 'PUBLIC SEO HTTP: PASSED'
