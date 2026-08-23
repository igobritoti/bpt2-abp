#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5100}"
WEB_PORT="${BPT_BUYER_WEB_PORT:-3100}"
BASE="http://127.0.0.1:${PORT}"
WEB_ROOT="http://127.0.0.1:${WEB_PORT}"
CLIENT_ID="BomPraTi_BuyerWeb"
REDIRECT_URI="${WEB_ROOT}/favoritos/callback"
TMP="${TMPDIR:-/tmp}/bpt2-buyer-favorites"
LOG="$TMP/api.log"; WEB_LOG="$TMP/web.log"; RESPONSE="$TMP/response.json"; HEADERS="$TMP/headers.txt"; COOKIES="$TMP/cookies.txt"; LOGIN_HTML="$TMP/login.html"; TOKEN_JSON="$TMP/token.json"; SWAGGER="$TMP/swagger.json"
: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"
: "${BPT_FIXTURE_VEHICLE_ID:?BPT_FIXTURE_VEHICLE_ID is required}"
rm -rf "$TMP"; mkdir -p "$TMP"
export ConnectionStrings__Default="$BPT_DB_CONNECTION" ASPNETCORE_URLS="$BASE" ASPNETCORE_ENVIRONMENT=Development App__SelfUrl="$BASE" AuthServer__Authority="$BASE" AuthServer__RequireHttpsMetadata=false OpenIddict__Applications__BomPraTi_BuyerWeb__RootUrl="$WEB_ROOT"
API_PID=""; WEB_PID=""; cleanup(){ [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true; [[ -z "$API_PID" ]] || kill "$API_PID" >/dev/null 2>&1 || true; }; trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo
dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 & API_PID=$!
for _ in $(seq 1 60); do curl --fail --silent "$BASE/swagger/v1/swagger.json" -o "$SWAGGER" && break; sleep 1; done
[[ -s "$SWAGGER" ]] || { cat "$LOG" >&2; exit 1; }
python3 - "$SWAGGER" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f: paths=json.load(f)['paths']
expected={
 '/api/app/favorite/mine':'get',
 '/api/app/favorite/is-favorite/{listingId}':'get',
 '/api/app/favorite':'post',
}
for path, verb in expected.items():
    if path not in paths or verb not in paths[path]: raise SystemExit(f'Missing expected Favorite route {verb.upper()} {path}; favorite routes={{p:list(paths[p]) for p in paths if "favorite" in p}}')
if 'delete' not in paths['/api/app/favorite']: raise SystemExit('Missing Favorite DELETE route')
print('BUYER_FAVORITE_ROUTES: PASS')
PY

ADMIN_TOKEN="$(curl --silent -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode 'username=admin' --data-urlencode 'password=1q2w3E*' --data-urlencode 'scope=BomPraTi' | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])')"
request(){ local method="$1" path="$2" token="${3:-}" body="${4:-}"; local a=(--silent --show-error --output "$RESPONSE" --write-out '%{http_code}' --request "$method"); [[ -z "$token" ]] || a+=(-H "Authorization: Bearer $token"); [[ -z "$body" ]] || a+=(-H 'Content-Type: application/json' --data "$body"); curl "${a[@]}" "$BASE$path"; }
get_fixture_token(){
  local username="$1"
  local password="$2"
  local token_file="$TMP/token-${username}.json"
  local status
  status="$(curl --silent --show-error --output "$token_file" --write-out '%{http_code}' -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=password' --data-urlencode 'client_id=BomPraTi_App' --data-urlencode "username=$username" --data-urlencode "password=$password" --data-urlencode 'scope=BomPraTi')"
  [[ "$status" == 200 ]] || { echo "Fixture token for $username expected 200 got $status: $(cat "$token_file")" >&2; return 1; }
  python3 - "$token_file" <<'PY'
import json,sys
data=json.load(open(sys.argv[1])); token=data.get('access_token')
if not token: raise SystemExit(f'Missing access_token: {data}')
print(token)
PY
}
request POST '/api/app/seller-profile/upsert' "$ADMIN_TOKEN" '{"displayName":"Buyer Favorite Fixture","whatsAppNumber":"5511999991111"}' >/dev/null
CREATE_BODY="$(python3 - "$BPT_FIXTURE_VEHICLE_ID" <<'PY'
import json,sys
print(json.dumps({'vehicleId':sys.argv[1],'title':'Buyer Favorite Fixture','price':123000,'description':'Fixture Buyer Favorites','manufactureYear':2024,'mileageKm':9000,'color':'Prata','city':'São Paulo','stateCode':'SP'}))
PY
)"
status="$(request POST '/api/app/listing-command' "$ADMIN_TOKEN" "$CREATE_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { cat "$RESPONSE"; exit 1; }
LISTING_ID="$(python3 - "$RESPONSE" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['id'])
PY
)"
FAVORITE_PATH="/api/app/favorite?listingId=$LISTING_ID"
status="$(request POST "$FAVORITE_PATH")"; [[ "$status" == 401 ]] || { echo "Anonymous favorite expected 401 got $status" >&2; exit 1; }
echo 'BUYER_FAVORITE_ANONYMOUS_BLOCKED: PASS'

read -r VERIFIER CHALLENGE STATE < <(python3 <<'PY'
import base64,hashlib,secrets
v=secrets.token_urlsafe(72)[:96]; c=base64.urlsafe_b64encode(hashlib.sha256(v.encode()).digest()).rstrip(b'=').decode(); print(v,c,secrets.token_urlsafe(24))
PY
)
AUTH_URL="$(python3 - "$BASE" "$CLIENT_ID" "$REDIRECT_URI" "$CHALLENGE" "$STATE" <<'PY'
import sys
from urllib.parse import urlencode
b,c,r,ch,s=sys.argv[1:]; print(b+'/connect/authorize?'+urlencode({'client_id':c,'redirect_uri':r,'response_type':'code','scope':'openid profile email roles BomPraTi','code_challenge':ch,'code_challenge_method':'S256','state':s}))
PY
)"
status="$(curl --silent --output "$RESPONSE" --dump-header "$HEADERS" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTH_URL")"; [[ "$status" == 302 ]] || { cat "$RESPONSE"; exit 1; }
location(){ awk 'BEGIN{IGNORECASE=1}/^location:/{sub(/\r$/,""); sub(/^[^:]+:[[:space:]]*/,""); print; exit}' "$1"; }
LOGIN_URL="$(python3 - "$BASE" "$(location "$HEADERS")" <<'PY'
import sys; from urllib.parse import urljoin; print(urljoin(sys.argv[1]+'/',sys.argv[2]))
PY
)"
LOGIN_EFFECTIVE="$(curl --silent --location --max-redirs 5 --cookie "$COOKIES" --cookie-jar "$COOKIES" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$LOGIN_URL")"
TOKEN_FIELD="$(python3 - "$LOGIN_HTML" <<'PY'
from html.parser import HTMLParser
import sys
class P(HTMLParser):
 v=None
 def handle_starttag(self,t,a):
  d=dict(a)
  if t=='input' and d.get('name')=='__RequestVerificationToken': self.v=d.get('value')
p=P(); p.feed(open(sys.argv[1],encoding='utf-8').read()); print(p.v or '')
PY
)"; [[ -n "$TOKEN_FIELD" ]] || exit 1
status="$(curl --silent --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' -X POST "$LOGIN_EFFECTIVE" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode "__RequestVerificationToken=$TOKEN_FIELD" --data-urlencode 'LoginInput.UserNameOrEmailAddress=admin' --data-urlencode 'LoginInput.Password=1q2w3E*' --data-urlencode 'LoginInput.RememberMe=false' --data-urlencode 'Action=Login')"; [[ "$status" == 302 ]] || exit 1
AUTHORIZED="$(python3 - "$BASE" "$(location "$HEADERS")" <<'PY'
import sys; from urllib.parse import urljoin; print(urljoin(sys.argv[1]+'/',sys.argv[2]))
PY
)"
status="$(curl --silent --output "$RESPONSE" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTHORIZED")"; [[ "$status" == 302 ]] || exit 1
CALLBACK="$(location "$HEADERS")"
read -r CODE RETURNED_STATE < <(python3 - "$CALLBACK" <<'PY'
import sys; from urllib.parse import urlparse,parse_qs
q=parse_qs(urlparse(sys.argv[1]).query); print(q['code'][0],q['state'][0])
PY
); [[ "$RETURNED_STATE" == "$STATE" ]] || exit 1
status="$(curl --silent --output "$TOKEN_JSON" --write-out '%{http_code}' -X POST "$BASE/connect/token" -H 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'grant_type=authorization_code' --data-urlencode "client_id=$CLIENT_ID" --data-urlencode "code=$CODE" --data-urlencode "redirect_uri=$REDIRECT_URI" --data-urlencode "code_verifier=$VERIFIER")"; [[ "$status" == 200 ]] || { cat "$TOKEN_JSON"; exit 1; }
BUYER_TOKEN="$(python3 - "$TOKEN_JSON" <<'PY'
import json,sys
print(json.load(open(sys.argv[1]))['access_token'])
PY
)"
echo 'BUYER_AUTH_PKCE_TOKEN: PASS'

status="$(request POST "$FAVORITE_PATH" "$BUYER_TOKEN")"; [[ "$status" == 404 ]] || { echo "Draft favorite expected 404 got $status" >&2; cat "$RESPONSE"; exit 1; }
echo 'BUYER_FAVORITE_DRAFT_BLOCKED: PASS'
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
for _ in 1 2; do status="$(request POST "$FAVORITE_PATH" "$BUYER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || { cat "$RESPONSE"; exit 1; }; done
echo 'BUYER_FAVORITE_IDEMPOTENT_ADD: PASS'
status="$(request GET '/api/app/favorite/mine' "$BUYER_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert len(x)==1 and x[0]['id']==sys.argv[2],x
PY
echo 'BUYER_FAVORITE_MINE: PASS'
status="$(request GET "/api/app/favorite/is-favorite/$LISTING_ID" "$BUYER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == true ]] || exit 1

OTHER_USER="buyer-favorite-$(python3 - <<'PY'
import uuid
print(uuid.uuid4().hex[:10])
PY
)"
OTHER_PASSWORD='Bpt2-BuyerFavorite-9!x'
OTHER_EMAIL="${OTHER_USER}@example.invalid"
OTHER_BODY="$(python3 - "$OTHER_USER" "$OTHER_EMAIL" "$OTHER_PASSWORD" <<'PY'
import json,sys
username,email,password=sys.argv[1:]
print(json.dumps({'userName':username,'name':'Other','surname':'Buyer','email':email,'password':password,'isActive':True,'lockoutEnabled':True,'roleNames':[]}))
PY
)"
status="$(request POST '/api/identity/users' "$ADMIN_TOKEN" "$OTHER_BODY")"; [[ "$status" == 200 || "$status" == 201 ]] || { echo "Second Buyer create failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
OTHER_TOKEN="$(get_fixture_token "$OTHER_USER" "$OTHER_PASSWORD")"
status="$(request GET '/api/app/favorite/mine' "$OTHER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || { echo "Second Buyer unexpectedly saw first Buyer's favorite" >&2; cat "$RESPONSE"; exit 1; }
status="$(request GET "/api/app/favorite/is-favorite/$LISTING_ID" "$OTHER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == false ]] || { echo "Second Buyer favorite state leaked" >&2; cat "$RESPONSE"; exit 1; }
status="$(request POST "$FAVORITE_PATH" "$OTHER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || { echo "Second Buyer add failed: $status $(cat "$RESPONSE")" >&2; exit 1; }
status="$(request GET '/api/app/favorite/mine' "$OTHER_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert len(x)==1 and x[0]['id']==sys.argv[2],x
PY
echo 'BUYER_FAVORITE_USER_ISOLATION: PASS'

status="$(request POST "/api/app/listing-command/pause/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
for token in "$BUYER_TOKEN" "$OTHER_TOKEN"; do
  status="$(request GET '/api/app/favorite/mine' "$token")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || { cat "$RESPONSE"; exit 1; }
done
echo 'BUYER_FAVORITE_PUBLIC_VISIBILITY: PASS'
status="$(request POST "/api/app/listing-command/publish/$LISTING_ID" "$ADMIN_TOKEN")"; [[ "$status" == 200 ]] || exit 1
for token in "$BUYER_TOKEN" "$OTHER_TOKEN"; do
  status="$(request GET '/api/app/favorite/mine' "$token")"; [[ "$status" == 200 ]] || exit 1
  python3 - "$RESPONSE" <<'PY'
import json,sys; assert len(json.load(open(sys.argv[1])))==1
PY
done
status="$(request DELETE "$FAVORITE_PATH" "$BUYER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || exit 1
status="$(request GET '/api/app/favorite/mine' "$BUYER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || exit 1
status="$(request GET '/api/app/favorite/mine' "$OTHER_TOKEN")"; [[ "$status" == 200 ]] || exit 1
python3 - "$RESPONSE" "$LISTING_ID" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert len(x)==1 and x[0]['id']==sys.argv[2],x
PY
status="$(request DELETE "$FAVORITE_PATH" "$OTHER_TOKEN")"; [[ "$status" == 200 || "$status" == 204 ]] || exit 1
status="$(request GET '/api/app/favorite/mine' "$OTHER_TOKEN")"; [[ "$status" == 200 && "$(cat "$RESPONSE")" == '[]' ]] || exit 1
echo 'BUYER_FAVORITE_REMOVE: PASS'

pushd "$ROOT/public-web" >/dev/null
npm install --no-audit --no-fund
BPT_API_BASE_URL="$BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$BASE" NEXT_PUBLIC_BPT_AUTHORITY="$BASE" NEXT_PUBLIC_BPT_BUYER_CLIENT_ID="$CLIENT_ID" npm run build
BPT_API_BASE_URL="$BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$BASE" NEXT_PUBLIC_BPT_AUTHORITY="$BASE" NEXT_PUBLIC_BPT_BUYER_CLIENT_ID="$CLIENT_ID" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 60); do curl --fail --silent "$WEB_ROOT/favoritos" -o "$TMP/favorites.html" && break; sleep 1; done
grep -Fq 'Meus favoritos' "$TMP/favorites.html" || { cat "$WEB_LOG"; exit 1; }
curl --fail --silent "$WEB_ROOT/anuncios/$LISTING_ID" -o "$TMP/detail.html"
grep -Fq 'Entrar e salvar nos favoritos' "$TMP/detail.html" || { echo 'Favorite CTA missing from detail' >&2; exit 1; }
echo 'BUYER_FAVORITE_WEB: PASS'
echo 'BUYER FAVORITES HTTP: PASSED'
