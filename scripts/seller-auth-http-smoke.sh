#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PORT="${BPT_API_PORT:-5094}"
BASE="http://127.0.0.1:${PORT}"
LOG="${TMPDIR:-/tmp}/bpt2-seller-auth.log"
RESPONSE="${TMPDIR:-/tmp}/bpt2-seller-auth-response.txt"
HEADERS="${TMPDIR:-/tmp}/bpt2-seller-auth-headers.txt"

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
