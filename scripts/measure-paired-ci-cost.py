#!/usr/bin/env python3
import argparse
import json
import os
import shutil
import subprocess
import tempfile
import time
from pathlib import Path
from statistics import median

ROOT = Path(__file__).resolve().parents[1]


def run(cmd, cwd):
    start = time.monotonic()
    proc = subprocess.run(cmd, cwd=cwd, shell=True)
    return time.monotonic() - start, proc.returncode


def copy_combined(dst):
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns('.git', 'artifacts', '**/bin', '**/obj', 'node_modules', '.next'))


def copy_backend(dst):
    shutil.copytree(ROOT, dst, ignore=shutil.ignore_patterns('.git', 'public-web', 'artifacts', '**/bin', '**/obj', 'node_modules', '.next'))


def copy_frontend(dst):
    shutil.copytree(ROOT / 'public-web', dst, ignore=shutil.ignore_patterns('node_modules', '.next'))


def combined(rep):
    with tempfile.TemporaryDirectory(prefix=f'bpt2-combined-{rep}-') as td:
        tree = Path(td) / 'repo'
        t0 = time.monotonic(); copy_combined(tree); materialize = time.monotonic() - t0
        backend, b_rc = run('dotnet build main/BomPraTi/BomPraTi.csproj --configuration Release --nologo', tree)
        install, i_rc = run('npm ci --no-audit --no-fund', tree / 'public-web')
        check, c_rc = run('npm run check', tree / 'public-web')
        command = backend + install + check
        return {'materialize_s': materialize, 'backend_s': backend, 'frontend_install_s': install, 'frontend_check_s': check,
                'command_s': command, 'total_s': materialize + command, 'pass': b_rc == i_rc == c_rc == 0}


def split(rep):
    with tempfile.TemporaryDirectory(prefix=f'bpt2-split-{rep}-') as td:
        base = Path(td); backend_tree = base / 'backend'; frontend_tree = base / 'frontend'
        t0 = time.monotonic(); copy_backend(backend_tree); backend_materialize = time.monotonic() - t0
        t0 = time.monotonic(); copy_frontend(frontend_tree); frontend_materialize = time.monotonic() - t0
        backend, b_rc = run('dotnet build main/BomPraTi/BomPraTi.csproj --configuration Release --nologo', backend_tree)
        install, i_rc = run('npm ci --no-audit --no-fund', frontend_tree)
        check, c_rc = run('npm run check', frontend_tree)
        frontend = install + check
        return {'backend_materialize_s': backend_materialize, 'frontend_materialize_s': frontend_materialize,
                'backend_s': backend, 'frontend_install_s': install, 'frontend_check_s': check,
                'backend_stream_s': backend_materialize + backend, 'frontend_stream_s': frontend_materialize + frontend,
                'compute_s': backend_materialize + backend + frontend_materialize + frontend,
                'critical_path_s': max(backend_materialize + backend, frontend_materialize + frontend),
                'pass': b_rc == i_rc == c_rc == 0}


def ratio(a, b):
    return a / b if b else None


def main():
    ap = argparse.ArgumentParser(); ap.add_argument('--pairs', type=int, default=5); ap.add_argument('--output', required=True)
    args = ap.parse_args()
    observations = []
    for rep in range(1, args.pairs + 1):
        order = ['combined', 'split'] if rep % 2 else ['split', 'combined']
        result = {'pair': rep, 'order': order}
        for condition in order:
            result[condition] = combined(rep) if condition == 'combined' else split(rep)
        result['valid'] = result['combined']['pass'] and result['split']['pass']
        observations.append(result)
    valid = [x for x in observations if x['valid']]
    summary = {'valid_pairs': len(valid), 'required_pairs': args.pairs}
    if valid:
        c_command = median(x['combined']['command_s'] for x in valid)
        c_total = median(x['combined']['total_s'] for x in valid)
        s_compute = median(x['split']['compute_s'] for x in valid)
        s_critical = median(x['split']['critical_path_s'] for x in valid)
        summary.update({'combined_command_median_s': c_command, 'combined_total_median_s': c_total,
                        'split_compute_median_s': s_compute, 'split_critical_path_median_s': s_critical,
                        'split_compute_vs_combined_total_ratio': ratio(s_compute, c_total),
                        'split_critical_vs_combined_total_ratio': ratio(s_critical, c_total)})
    measured_head_sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    payload = {'schema_version': 1, 'head_sha': measured_head_sha, 'github_event_sha': os.getenv('GITHUB_SHA'),
               'pairs': observations, 'summary': summary,
               'scope': 'paired same-runner build/check probe; split critical path is modeled max(streams), not observed two-job elapsed time'}
    Path(args.output).write_text(json.dumps(payload, indent=2, sort_keys=True) + '\n')
    print(json.dumps(summary, indent=2, sort_keys=True))
    if len(valid) < args.pairs:
        raise SystemExit(2)

if __name__ == '__main__':
    main()
