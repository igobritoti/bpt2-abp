#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_SEO_API_PORT:-5098}"
WEB_PORT="${BPT_SEO_WEB_PORT:-3098}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-public-seo"
RESPONSE="$TMP/response.json"; API_LOG="$TMP/api.log"; WEB_LOG="$TMP/web.log"; ROBOTS="$TMP/robots.txt"; SITEMAP="$TMP/sitemap.xml"; DETAIL="$TMP/detail.html"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$API_BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$API_BASE" AuthServer__Authority="$API_BASE"
API_PID=""; WEB_PID=""
cleanup(){ [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true; [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$API_BASE$path"; }
token(){ curl --silent -X POST "$API_BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode 'username=admin' --data-urlencode 'password=1q2w3E*' --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'; }

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null && break; sleep 1; done
curl --fail --silent "$API_BASE/swagger/v1/swagger.json" >/dev/null || { cat "$API_LOG" >&2; exit 1; }
ADMIN_TOKEN="$(token)"
request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"SEO Fixture","whatsAppNumber":"5511999993333"}' >/dev/null
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'SEO public listing fixture','price':99000,'description':'Fixture para sitemap e canonical.','manufactureYear':2024,'mileageKm':5000,'color':'Prata','city':'Curitiba','stateCode':'PR'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys; print(json.load(open(sys.argv[1]))['id'])
PY
)"

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run build
BPT_API_BASE_URL="$API_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" BPT_PUBLIC_BASE_URL="$WEB_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do curl --fail --silent "$WEB_BASE/robots.txt" -o "$ROBOTS" && break; sleep 1; done
curl --fail --silent "$WEB_BASE/robots.txt" -o "$ROBOTS" || { cat "$WEB_LOG" >&2; exit 1; }
grep -Fq 'Disallow: /favoritos' "$ROBOTS" && grep -Fq 'Disallow: /vender' "$ROBOTS" && grep -Fq 'Disallow: /api/' "$ROBOTS" && grep -Fq "Sitemap: $WEB_BASE/sitemap.xml" "$ROBOTS" || { cat "$ROBOTS" >&2; exit 1; }
echo 'PUBLIC_SEO_ROBOTS: PASS'

curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
grep -Fq "<loc>$WEB_BASE/</loc>" "$SITEMAP" || { cat "$SITEMAP" >&2; exit 1; }
if grep -Fq "/anuncios/$LISTING_ID" "$SITEMAP"; then echo 'Draft Listing leaked into sitemap.' >&2; exit 1; fi
echo 'PUBLIC_SEO_DRAFT_EXCLUDED: PASS'

status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
grep -Fq "<loc>$WEB_BASE/anuncios/$LISTING_ID</loc>" "$SITEMAP" || { cat "$SITEMAP" >&2; exit 1; }
echo 'PUBLIC_SEO_PUBLISHED_IN_SITEMAP: PASS'

status="$(curl --silent --show-error --output "$DETAIL" --write-out '%{http_code}' "$WEB_BASE/anuncios/$LISTING_ID")"; [[ "$status" == 200 ]] || { cat "$WEB_LOG" >&2; exit 1; }
grep -Fq "rel=\"canonical\" href=\"$WEB_BASE/anuncios/$LISTING_ID\"" "$DETAIL" || { echo 'Canonical missing.' >&2; grep -o 'canonical[^>]*' "$DETAIL" >&2 || true; exit 1; }
echo 'PUBLIC_SEO_CANONICAL: PASS'

status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || { cat "$RESPONSE"; exit 1; }
curl --fail --silent "$WEB_BASE/sitemap.xml" -o "$SITEMAP"
if grep -Fq "/anuncios/$LISTING_ID" "$SITEMAP"; then echo 'Paused Listing remained in sitemap.' >&2; exit 1; fi
echo 'PUBLIC_SEO_PAUSED_EXCLUDED: PASS'
echo 'PUBLIC SEO HTTP: PASSED'
