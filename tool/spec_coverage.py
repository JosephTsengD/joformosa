#!/usr/bin/env python3
"""
spec ↔ test 的機器可驗證連結。

docs/tasks/*.spec.md 裡的每個 `Scenario: X` 都必須有測試以
`// @spec T-042/Scenario-X` 標記。少一個就 fail。

status 生命週期：planned → spec_frozen → done
只有 spec_frozen 與 done 會被檢查——規劃師必須能提前寫規格而不讓 CI 變紅。

為什麼是 Python 而不是 shell（第三次踩到才改）：
  1. BSD sed / grep 不支援 \\s（macOS 上靜默失效）
  2. bash 3.2 在非 UTF-8 locale 下，把 `$id（` 的高位元組吃進變數名，
     報成 `id?: unbound variable`——訊息完全看不出真因
CJK 內容的腳本，用 Python 寫就沒有這些問題。
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHECKED = {'spec_frozen', 'done'}

missing = []
checked = skipped = 0

for spec in sorted((ROOT / 'docs' / 'tasks').glob('*.spec.md')):
    task_id = spec.name.removesuffix('.spec.md')
    text = spec.read_text()

    status_match = re.search(r'^status:\s*(\S+)', text, re.M)
    status = status_match.group(1) if status_match else ''
    if status not in CHECKED:
        print(f'  skip {task_id} (status: {status or "未標示"})')
        skipped += 1
        continue
    checked += 1

    test_sources = '\n'.join(
        f.read_text()
        for d in ('test', 'integration_test')
        for f in (ROOT / d).rglob('*.dart')
        if (ROOT / d).exists()
    )

    for m in re.finditer(r'^\s*Scenario:\s*(.+?)\s*$', text, re.M):
        name = re.sub(r'\s+', '-', m.group(1).strip())
        marker = f'@spec {task_id}/Scenario-{name}'
        if marker not in test_sources:
            missing.append(f'{task_id} / Scenario: {name}')

for entry in missing:
    print(f'missing test for {entry}')

if missing:
    print(f'{len(missing)} 個驗收條件沒有對應測試')
    sys.exit(1)

print(f'spec coverage ok（檢查 {checked} 份規格，略過 {skipped} 份規劃中）')
