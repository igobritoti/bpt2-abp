#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_PORT="${BPT_SELLER_AUTH_API_PORT:-5094}"
WEB_PORT="${BPT_SELLER_AUTH_WEB_PORT:-3094}"
API_BASE="http://127.0.0.1:${API_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
CLIENT_ID="BomPraTi_SellerWeb"
REDIRECT_URI="${WEB_BASE}/auth/callback"
LOGOUT_REDIRECT_URI="${WEB_BASE}/auth/logout-callback"
TMP="${TMPDIR:-/tmp}/bpt2-seller-auth"
API_LOG="${TMP}/api.log"
WEB_LOG="${TMP}/web.log"
COOKIES="${TMP}/cookies.txt"
HEADERS="${TMP}/headers.txt"
BODY="${TMP}/body.txt"
LOGIN_HTML="${TMP}/login.html"
TOKEN_JSON="${TMP}/token.json"
SWAGGER="${TMP}/swagger.json"
DISCOVERY="${TMP}/discovery.json"

: "${BPT_DB_CONNECTION:?BPT_DB_CONNECTION is required}"

rm -rf "$TMP"
mkdir -p "$TMP"

export ConnectionStrings__Default="$BPT_DB_CONNECTION"
export ASPNETCORE_URLS="$API_BASE"
export ASPNETCORE_ENVIRONMENT=Development
export App__SelfUrl="$API_BASE"
export App__CorsOrigins="$WEB_BASE"
export App__RedirectAllowedUrls="$WEB_BASE"
export AuthServer__Authority="$API_BASE"
export AuthServer__RequireHttpsMetadata=false

BACKEND_PID=""
WEB_PID=""
cleanup() {
  [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true
  [[ -z "$BACKEND_PID" ]] || kill "$BACKEND_PID" >/dev/null 2>&1 || true
}
trap cleanup EXIT

dotnet build "$ROOT/main/BomPraTi/BomPraTi.csproj" --configuration Release --nologo

dotnet "$ROOT/main/BomPraTi/bin/Release/net10.0/BomPraTi.dll" >"$API_LOG" 2>&1 &
BACKEND_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$API_BASE/.well-known/openid-configuration" -o "$DISCOVERY" && \
     curl --fail --silent --show-error "$API_BASE/swagger/v1/swagger.json" -o "$SWAGGER"; then
    break
  fi
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    cat "$API_LOG" >&2
    exit 1
  fi
  sleep 1
done

[[ -s "$DISCOVERY" && -s "$SWAGGER" ]] || { cat "$API_LOG" >&2; echo "Auth server did not become ready." >&2; exit 1; }

python3 - "$DISCOVERY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
required = ["authorization_endpoint", "token_endpoint", "end_session_endpoint"]
missing = [key for key in required if not data.get(key)]
if missing:
    raise SystemExit(f"OIDC discovery missing endpoints: {missing}")
if "S256" not in data.get("code_challenge_methods_supported", []):
    raise SystemExit("OIDC discovery does not advertise S256 PKCE")
PY
echo "SELLER_AUTH_DISCOVERY: PASS"

(
  cd "$ROOT/public-web"
  npm install --no-audit --no-fund
  NEXT_PUBLIC_BPT_AUTHORITY="$API_BASE" \
  NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" \
  NEXT_PUBLIC_BPT_SELLER_CLIENT_ID="$CLIENT_ID" \
  BPT_API_BASE_URL="$API_BASE" \
    npm run build
  NEXT_PUBLIC_BPT_AUTHORITY="$API_BASE" \
  NEXT_PUBLIC_BPT_API_BASE_URL="$API_BASE" \
  NEXT_PUBLIC_BPT_SELLER_CLIENT_ID="$CLIENT_ID" \
  BPT_API_BASE_URL="$API_BASE" \
    npm run start -- --hostname 127.0.0.1 --port "$WEB_PORT" >"$WEB_LOG" 2>&1
) &
WEB_PID=$!

for _ in $(seq 1 60); do
  if curl --fail --silent --show-error "$WEB_BASE/vender" -o "$BODY"; then
    break
  fi
  if ! kill -0 "$WEB_PID" >/dev/null 2>&1; then
    cat "$WEB_LOG" >&2
    exit 1
  fi
  sleep 1
done

grep -q "Bom Pra Ti Seller" "$BODY" || { cat "$BODY" >&2; echo "Seller entry page marker missing." >&2; exit 1; }
echo "SELLER_AUTH_UI_SHELL: PASS"

read -r CODE_VERIFIER CODE_CHALLENGE STATE < <(python3 <<'PY'
import base64, hashlib, secrets
verifier = secrets.token_urlsafe(72)[:96]
challenge = base64.urlsafe_b64encode(hashlib.sha256(verifier.encode()).digest()).rstrip(b"=").decode()
print(verifier, challenge, secrets.token_urlsafe(24))
PY
)

AUTH_URL="$(python3 - "$API_BASE" "$CLIENT_ID" "$REDIRECT_URI" "$CODE_CHALLENGE" "$STATE" <<'PY'
import sys
from urllib.parse import urlencode
base, client, redirect, challenge, state = sys.argv[1:]
query = urlencode({
    "client_id": client,
    "redirect_uri": redirect,
    "response_type": "code",
    "scope": "openid profile email roles BomPraTi",
    "code_challenge": challenge,
    "code_challenge_method": "S256",
    "state": state,
})
print(f"{base}/connect/authorize?{query}")
PY
)"

status="$(curl --silent --show-error --output "$BODY" --dump-header "$HEADERS" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTH_URL")"
[[ "$status" == "302" ]] || { cat "$BODY" >&2; echo "Authorize expected 302 to login, got $status" >&2; exit 1; }

location() {
  python3 - "$1" <<'PY'
import sys
value = None
with open(sys.argv[1], encoding="iso-8859-1") as handle:
    for line in handle:
        if line.lower().startswith("location:"):
            value = line.split(":", 1)[1].strip()
if not value:
    raise SystemExit("Missing Location header")
print(value)
PY
}

resolve_url() {
  python3 - "$API_BASE" "$1" <<'PY'
import sys
from urllib.parse import urljoin
print(urljoin(sys.argv[1] + "/", sys.argv[2]))
PY
}

LOGIN_URL="$(resolve_url "$(location "$HEADERS")")"
LOGIN_EFFECTIVE="$(curl --silent --show-error --location --max-redirs 5 --cookie "$COOKIES" --cookie-jar "$COOKIES" --output "$LOGIN_HTML" --write-out '%{url_effective}' "$LOGIN_URL")"

REQUEST_TOKEN="$(python3 - "$LOGIN_HTML" <<'PY'
from html.parser import HTMLParser
import sys
class Parser(HTMLParser):
    value = None
    def handle_starttag(self, tag, attrs):
        if tag.lower() != "input":
            return
        values = dict(attrs)
        if values.get("name") == "__RequestVerificationToken":
            self.value = values.get("value")
parser = Parser()
with open(sys.argv[1], encoding="utf-8") as handle:
    parser.feed(handle.read())
if not parser.value:
    raise SystemExit("Login antiforgery token not found")
print(parser.value)
PY
)"

status="$(curl --silent --show-error --output "$BODY" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' \
  --request POST "$LOGIN_EFFECTIVE" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "__RequestVerificationToken=$REQUEST_TOKEN" \
  --data-urlencode 'LoginInput.UserNameOrEmailAddress=admin' \
  --data-urlencode 'LoginInput.Password=1q2w3E*' \
  --data-urlencode 'LoginInput.RememberMe=false' \
  --data-urlencode 'Action=Login')"
[[ "$status" == "302" ]] || { cat "$BODY" >&2; echo "Account login expected 302, got $status" >&2; exit 1; }

AUTHORIZED_URL="$(resolve_url "$(location "$HEADERS")")"
status="$(curl --silent --show-error --output "$BODY" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$AUTHORIZED_URL")"
[[ "$status" == "302" ]] || { cat "$BODY" >&2; echo "Authenticated authorize expected 302, got $status" >&2; exit 1; }
CALLBACK_URL="$(location "$HEADERS")"

read -r AUTH_CODE RETURNED_STATE < <(python3 - "$CALLBACK_URL" "$WEB_BASE" <<'PY'
import sys
from urllib.parse import parse_qs, urlparse
url, expected_base = sys.argv[1:]
parsed = urlparse(url)
expected = urlparse(expected_base)
if (parsed.scheme, parsed.netloc, parsed.path) != (expected.scheme, expected.netloc, "/auth/callback"):
    raise SystemExit(f"Unexpected callback URL: {url}")
query = parse_qs(parsed.query)
if "error" in query:
    raise SystemExit(f"Authorization error: {query}")
print(query["code"][0], query["state"][0])
PY
)
[[ "$RETURNED_STATE" == "$STATE" ]] || { echo "OIDC state mismatch" >&2; exit 1; }
echo "SELLER_AUTH_LOGIN_REDIRECT: PASS"

status="$(curl --silent --show-error --output "$TOKEN_JSON" --write-out '%{http_code}' \
  --request POST "$API_BASE/connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=authorization_code' \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode "code=$AUTH_CODE" \
  --data-urlencode "redirect_uri=$REDIRECT_URI" \
  --data-urlencode "code_verifier=$CODE_VERIFIER")"
[[ "$status" == "200" ]] || { cat "$TOKEN_JSON" >&2; echo "PKCE code exchange expected 200, got $status" >&2; exit 1; }

read -r ACCESS_TOKEN ID_TOKEN < <(python3 - "$TOKEN_JSON" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if not data.get("access_token") or not data.get("id_token"):
    raise SystemExit(f"Token response missing access/id token: {data}")
print(data["access_token"], data["id_token"])
PY
)
echo "SELLER_AUTH_PKCE_EXCHANGE: PASS"

SELLER_CURRENT_PATH="$(python3 - "$SWAGGER" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
candidates = []
for path, operations in data.get("paths", {}).items():
    operation = operations.get("get")
    if not operation or "seller-profile" not in path:
        continue
    haystack = f"{path} {operation.get('operationId', '')}".lower()
    if "current" in haystack:
        candidates.append(path)
if not candidates:
    raise SystemExit("Seller current profile GET route not found")
print(sorted(candidates, key=len)[0])
PY
)"

status="$(curl --silent --show-error --output "$BODY" --write-out '%{http_code}' \
  -H "Authorization: Bearer $ACCESS_TOKEN" "$API_BASE$SELLER_CURRENT_PATH")"
[[ "$status" == "200" || "$status" == "204" ]] || { cat "$BODY" >&2; echo "Seller API bearer call expected 200/204, got $status" >&2; exit 1; }
echo "SELLER_AUTH_BEARER_API: PASS"

NO_PKCE_URL="$(python3 - "$API_BASE" "$CLIENT_ID" "$REDIRECT_URI" <<'PY'
import secrets, sys
from urllib.parse import urlencode
base, client, redirect = sys.argv[1:]
print(f"{base}/connect/authorize?" + urlencode({
    "client_id": client,
    "redirect_uri": redirect,
    "response_type": "code",
    "scope": "openid profile BomPraTi",
    "state": secrets.token_urlsafe(18),
}))
PY
)"
status="$(curl --silent --show-error --output "$BODY" --dump-header "$HEADERS" --cookie "$COOKIES" --write-out '%{http_code}' "$NO_PKCE_URL")"
if [[ "$status" == "400" ]]; then
  :
elif [[ "$status" == "302" ]]; then
  no_pkce_location="$(location "$HEADERS")"
  [[ "$no_pkce_location" == *"error="* ]] || { echo "Missing-PKCE request unexpectedly redirected without OAuth error: $no_pkce_location" >&2; exit 1; }
else
  cat "$BODY" >&2
  echo "Missing-PKCE request expected OAuth rejection, got $status" >&2
  exit 1
fi
echo "SELLER_AUTH_PKCE_REQUIRED: PASS"

status="$(curl --silent --show-error --output "$BODY" --write-out '%{http_code}' \
  --request POST "$API_BASE/connect/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'grant_type=password' \
  --data-urlencode "client_id=$CLIENT_ID" \
  --data-urlencode 'username=admin' \
  --data-urlencode 'password=1q2w3E*' \
  --data-urlencode 'scope=BomPraTi')"
[[ "$status" == "400" ]] || { cat "$BODY" >&2; echo "Seller client password grant must be rejected, got $status" >&2; exit 1; }
python3 - "$BODY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
if data.get("access_token"):
    raise SystemExit("Seller client unexpectedly received an access token via password grant")
PY
echo "SELLER_AUTH_PASSWORD_GRANT_REJECTED: PASS"

END_SESSION_ENDPOINT="$(python3 - "$DISCOVERY" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["end_session_endpoint"])
PY
)"
LOGOUT_URL="$(python3 - "$END_SESSION_ENDPOINT" "$ID_TOKEN" "$LOGOUT_REDIRECT_URI" <<'PY'
import secrets, sys
from urllib.parse import urlencode
endpoint, id_token, redirect = sys.argv[1:]
print(endpoint + "?" + urlencode({
    "id_token_hint": id_token,
    "post_logout_redirect_uri": redirect,
    "state": secrets.token_urlsafe(18),
}))
PY
)"
status="$(curl --silent --show-error --output "$BODY" --dump-header "$HEADERS" --cookie "$COOKIES" --cookie-jar "$COOKIES" --write-out '%{http_code}' "$LOGOUT_URL")"
[[ "$status" == "200" || "$status" == "302" ]] || { cat "$BODY" >&2; echo "End-session request expected 200/302, got $status" >&2; exit 1; }
echo "SELLER_AUTH_LOGOUT_ENDPOINT: PASS"

echo "SELLER AUTH PKCE FLOW: PASSED"
