#!/usr/bin/env python3
from __future__ import annotations

import importlib.util
import pathlib
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
WIRE = ROOT / "scripts" / "wire-host.py"
spec = importlib.util.spec_from_file_location("bpt_wire_host", WIRE)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

fixture = '''using Volo.Abp.Modularity;
namespace BomPraTi;

[DependsOn(
    typeof(SomeExistingModule)
)]
public class BomPraTiModule : AbpModule
{
    private void ConfigureAutoApiControllers()
    {
        Configure<AbpAspNetCoreMvcOptions>(options =>
        {
            options.ConventionalControllers.Create(typeof(BomPraTiModule).Assembly);
        });
    }
}
'''

with tempfile.TemporaryDirectory() as temp_dir:
    main_dir = pathlib.Path(temp_dir) / "main"
    host_dir = main_dir / "BomPraTi"
    host_dir.mkdir(parents=True)
    (host_dir / "BomPraTiModule.cs").write_text(fixture, encoding="utf-8")
    (host_dir / "BomPraTi.csproj").write_text("<Project />", encoding="utf-8")
    discovered_project, discovered_module = module.discover_host_artifacts(main_dir)
    assert discovered_project == host_dir / "BomPraTi.csproj"
    assert discovered_module == host_dir / "BomPraTiModule.cs"

patched = module.patch_host_module(fixture)
for using in module.MODULE_USINGS:
    assert patched.count(using) == 1, using
for name in module.MODULE_TYPES:
    assert patched.count(f"typeof({name})") == 2, name
    assert patched.count(f"options.ConventionalControllers.Create(typeof({name}).Assembly);") == 1, name

patched_again = module.patch_host_module(patched)
assert patched_again == patched

print("HOST WIRING TEST: PASSED")
