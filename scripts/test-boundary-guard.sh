#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECKER="$ROOT/scripts/check-boundaries.py"

run_attack() {
  local name="$1" attack_script="$2"
  local tmp
  tmp="$(mktemp -d)"
  cp -a "$ROOT/modules" "$tmp/modules"
  trap 'rm -rf "$tmp"' RETURN

  BPT_ATTACK_ROOT="$tmp" python3 -c "$attack_script"
  cp "$CHECKER" "$tmp/check-boundaries.py"
  python3 - "$tmp/check-boundaries.py" <<'PY'
from pathlib import Path
import sys
p = Path(sys.argv[1])
s = p.read_text()
s = s.replace('ROOT = pathlib.Path(__file__).resolve().parents[1]', 'ROOT = pathlib.Path(__file__).resolve().parent')
p.write_text(s)
PY

  set +e
  output="$(python3 "$tmp/check-boundaries.py" 2>&1)"
  code=$?
  set -e
  if [[ $code -eq 0 ]]; then
    echo "Boundary guard self-test FAILED: attack '$name' was accepted." >&2
    exit 1
  fi
  echo "PASS attack rejected: $name"
}

python3 "$CHECKER"

run_attack "Marketplace -> Catalog implementation project reference" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <ProjectReference Include=\"../../../catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj\" />\n  </ItemGroup>\n</Project>"))
'

run_attack "Marketplace -> Media implementation project reference" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <ProjectReference Include=\"../../../media/src/BomPraTi.Media/BomPraTi.Media.csproj\" />\n  </ItemGroup>\n</Project>"))
'

run_attack "Marketplace -> Sellers implementation project reference" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/marketplace/src/BomPraTi.Marketplace/BomPraTi.Marketplace.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <ProjectReference Include=\"../../../sellers/src/BomPraTi.Sellers/BomPraTi.Sellers.csproj\" />\n  </ItemGroup>\n</Project>"))
'

run_attack "Marketplace storage-provider key leakage" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/marketplace/src/BomPraTi.Marketplace/BoundaryAttack.cs"
p.write_text("namespace BomPraTi.Marketplace; internal sealed class BoundaryAttack { private string StorageKey = string.Empty; }\n")
'

run_attack "Catalog -> Marketplace.Contracts forbidden reverse edge" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/catalog/src/BomPraTi.Catalog/BomPraTi.Catalog.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <ProjectReference Include=\"../../../marketplace/src/BomPraTi.Marketplace.Contracts/BomPraTi.Marketplace.Contracts.csproj\" />\n  </ItemGroup>\n</Project>"))
'

run_attack "Catalog.Contracts -> Catalog implementation" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/catalog/src/BomPraTi.Catalog.Contracts/BomPraTi.Catalog.Contracts.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <ProjectReference Include=\"../BomPraTi.Catalog/BomPraTi.Catalog.csproj\" />\n  </ItemGroup>\n</Project>"))
'

run_attack "Fully-qualified Ingestion -> Catalog.Domain bypass" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/ingestion/src/BomPraTi.Ingestion/BoundaryAttack.cs"
p.parent.mkdir(parents=True, exist_ok=True)
p.write_text("namespace BomPraTi.Ingestion; internal sealed class BoundaryAttack { private BomPraTi.Catalog.Domain.Brand? _brand; }\n")
'

run_attack "Contracts -> EF infrastructure package" '
from pathlib import Path
import os
p=Path(os.environ["BPT_ATTACK_ROOT"])/"modules/marketplace/src/BomPraTi.Marketplace.Contracts/BomPraTi.Marketplace.Contracts.csproj"
s=p.read_text(); p.write_text(s.replace("</Project>", "  <ItemGroup>\n    <PackageReference Include=\"Microsoft.EntityFrameworkCore.Design\" />\n  </ItemGroup>\n</Project>"))
'

echo "Boundary guard self-test PASSED: all intentional architecture attacks were rejected."
