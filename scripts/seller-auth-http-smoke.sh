#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5094}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-seller-auth.log"
RESPONSE="${TMPDIR:-/tmp}/bpt2-seller-auth-response.txt"
HEADERS="${TMPDIR:-/tmp}/bpt2-seller-auth-headers.txt"
REGISTER_HTML="${TMPDIR:-/tmp}/bpt2-self-registration.html"
TOKEN_RESPONSE="${TMPDIR:-/tmp}/bpt2-self-registration-token.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$BASE"
export AuthServer__Authority="$BASE"
export AuthServer__RequireHttpsMetadata=false

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$LOG" 2>&1 &
APP_PID=$!
trap 'kill "$APP_PID" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$BASE/.well-known/openid-configuration" -o "$RESPONSE"; then
    break
  fi
  if ! kill -0 "$APP_PID" >/dev/null 2>&1; then
    cat "$LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$RESPONSE" ]] || { cat "$LOG" >&2; echo "OIDC discovery did not become available." >&2; exit 1; }
echo "SELLER_AUTH_DISCOVERY: PASS"

register_status="$(curl --silent --show-error --output "$REGISTER_HTML" --write-out '%{http_code}' "$BASE/Account/Register")"
[[ "$register_status" == "200" ]] || {
  echo "Account registration page expected 200, got $register_status" >&2
  cat "$REGISTER_HTML" >&2
  exit 1
}
for field in 'Input.UserName' 'Input.EmailAddress' 'Input.Password'; do
  grep -Fq "name=\"$field\"" "$REGISTER_HTML" || {
    echo "Account registration page missing $field input." >&2
    exit 1
  }
done
echo "SELF_REGISTRATION_PAGE: PASS"

SELF_REG_SUFFIX="$(date +%s)$$"
SELF_REG_USERNAME="selfreg${SELF_REG_SUFFIX}"
SELF_REG_EMAIL="${SELF_REG_USERNAME}@example.test"
SELF_REG_PASSWORD='Bpt2SelfReg!2026Aa'
REGISTER_BODY="$(python3 - "$SELF_REG_USERNAME" "$SELF_REG_EMAIL" "$SELF_REG_PASSWORD" <<'PY'
import json, sys
print(json.dumps({
    "userName": sys.argv[1],
    "emailAddress": sys.argv[2],
    "password": sys.argv[3],
    "appName": "MVC",
}))
PY
)"
register_api_status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' \
  -X POST "$BASE/api/account/register" \
  -H 'Content-Type: application/json' \
  --data "$REGISTER_BODY")"
[[ "$register_api_status" == "200" || "$register_api_status" == "201" ]] || {
  echo "Self-registration API expected 200/201, got $register_api_status" >&2
  cat "$RESPONSE" >&2
  exit 1
}
python3 - "$RESPONSE" "$SELF_REG_USERNAME" "$SELF_REG_EMAIL" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("userName") != sys.argv[2]:
    raise SystemExit(f"Registered username mismatch: {data}")
email = data.get("email") or data.get("emailAddress")
if email != sys.argv[3]:
    raise SystemExit(f"Registered email mismatch: {data}")
if not data.get("id"):
    raise SystemExit(f"Registration response missing user id: {data}")
PY
echo "SELF_REGISTRATION_CREATED: PASS"

token_status="$(curl --silent --show-error --output "$TOKEN_RESPONSE" --write-out '%{http_code}' \
  -X POST "$BASE/connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode 'client_id=BomPraTi_App' \
  --data-urlencode "username=$SELF_REG_USERNAME" \
  --data-urlencode "password=$SELF_REG_PASSWORD" \
  --data-urlencode 'scope=BomPraTi')"
[[ "$token_status" == "200" ]] || {
  echo "New self-registered user token expected 200, got $token_status" >&2
  cat "$TOKEN_RESPONSE" >&2
  exit 1
}
python3 - "$TOKEN_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if not data.get("access_token"):
    raise SystemExit(f"Token response missing access_token: {data}")
if data.get("token_type", "").lower() != "bearer":
    raise SystemExit(f"Unexpected token type: {data}")
PY
echo "SELF_REGISTRATION_LOGIN: PASS"

REDIRECT_URI='http%3A%2F%2Flocalhost%3A3000%2Fvender%2Fcallback'
AUTHORIZE="$BASE/connect/authorize?client_id=BomPraTi_SellerWeb&redirect_uri=$REDIRECT_URI&response_type=code&scope=openid%20profile%20BomPraTi"

status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' "$AUTHORIZE")"
[[ "$status" == "400" ]] || {
  echo "Authorization request without PKCE expected 400, got $status" >&2
  cat "$RESPONSE" >&2
  exit 1
}
echo "SELLER_AUTH_PKCE_REQUIRED: PASS"

CHALLENGE='E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'
status="$(curl --silent --show-error --dump-header "$HEADERS" --output "$RESPONSE" --write-out '%{http_code}' \
  "$AUTHORIZE&code_challenge=$CHALLENGE&code_challenge_method=S256")"

[[ "$status" == "302" ]] || {
  echo "Authorization request with PKCE expected login redirect 302, got $status" >&2
  cat "$HEADERS" >&2
  cat "$RESPONSE" >&2
  exit 1
}

grep -Eiq '^location: .*account/login' "$HEADERS" || {
  echo "Authorization request with PKCE did not redirect to the ABP login page." >&2
  cat "$HEADERS" >&2
  exit 1
}
echo "SELLER_AUTH_LOGIN_REDIRECT: PASS"

echo "SELLER AUTH HTTP SPIKE: PASSED"
