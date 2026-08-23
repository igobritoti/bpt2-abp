#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOCK_PORT="${BPT_LEAD_MOCK_PORT:-5199}"
WEB_PORT="${BPT_LEAD_WEB_PORT:-3199}"
MOCK_BASE="http://127.0.0.1:${MOCK_PORT}"
WEB_BASE="http://127.0.0.1:${WEB_PORT}"
TMP="${TMPDIR:-/tmp}/bpt2-lead-forwarding"
mkdir -p "$TMP"
MOCK_LOG="$TMP/mock.log"; WEB_LOG="$TMP/web.log"; RESPONSE="$TMP/response.json"
MOCK_PID=""; WEB_PID=""
cleanup(){ [[ -z "$WEB_PID" ]] || kill "$WEB_PID" >/dev/null 2>&1 || true; [[ -z "$MOCK_PID" ]] || kill "$MOCK_PID" >/dev/null 2>&1 || true; }
trap cleanup EXIT

cat > "$TMP/mock.py" <<'PY'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json, os
port=int(os.environ['MOCK_PORT'])
class H(BaseHTTPRequestHandler):
  def log_message(self,*args): pass
  def do_GET(self):
    if self.path != '/api/app/public-listing/11111111-1111-1111-1111-111111111111': self.send_response(404); self.end_headers(); return
    body={'id':'11111111-1111-1111-1111-111111111111','title':'Mock','price':1,'description':'Mock','manufactureYear':2024,'mileageKm':1,'color':'Preto','city':'São Paulo','stateCode':'SP','vehicle':{'brand':'B','model':'M','generation':'G','version':'V','modelYear':2024},'seller':{'displayName':'Seller','whatsAppNumber':'5511999998877'},'photos':[]}
    data=json.dumps(body).encode(); self.send_response(200); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
  def do_POST(self):
    if not self.path.startswith('/api/app/lead?listingId=11111111-1111-1111-1111-111111111111'): self.send_response(404); self.end_headers(); return
    auth=self.headers.get('Authorization')
    if auth != 'Bearer buyer-token-proof': self.send_response(401); self.end_headers(); return
    print('AUTH_FORWARDING_RECEIVED', flush=True)
    data=b'{}'; self.send_response(200); self.send_header('Content-Type','application/json'); self.send_header('Content-Length',str(len(data))); self.end_headers(); self.wfile.write(data)
HTTPServer(('127.0.0.1',port),H).serve_forever()
PY
MOCK_PORT="$MOCK_PORT" python3 "$TMP/mock.py" >"$MOCK_LOG" 2>&1 & MOCK_PID=$!

pushd "$ROOT/public-web" >/dev/null
BPT_API_BASE_URL="$MOCK_BASE" NEXT_PUBLIC_BPT_API_BASE_URL="$MOCK_BASE" npm run start -- -p "$WEB_PORT" >"$WEB_LOG" 2>&1 & WEB_PID=$!
popd >/dev/null
for _ in $(seq 1 30); do curl --fail --silent "$WEB_BASE/anuncios/11111111-1111-1111-1111-111111111111" >/dev/null && break; sleep 1; done
status="$(curl --silent --show-error --output "$RESPONSE" --write-out '%{http_code}' -X POST "$WEB_BASE/api/contact/whatsapp" -H 'Accept: application/json' -H 'Authorization: Bearer buyer-token-proof' -F 'listingId=11111111-1111-1111-1111-111111111111')"
[[ "$status" == 200 ]] || { echo "Authenticated contact expected 200 got $status: $(cat "$RESPONSE")" >&2; cat "$WEB_LOG" >&2; exit 1; }
python3 - "$RESPONSE" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['url']=='https://wa.me/5511999998877',x
PY
grep -Fq 'AUTH_FORWARDING_RECEIVED' "$MOCK_LOG" || { echo 'Authorization header was not forwarded to Lead API.' >&2; cat "$MOCK_LOG" >&2; exit 1; }
grep -Fq 'getCurrentBuyerUser' "$ROOT/public-web/app/anuncios/[id]/WhatsAppContactButton.tsx"
echo 'AUTHENTICATED_LEAD_FORWARDING: PASS'
