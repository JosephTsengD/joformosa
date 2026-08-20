#!/usr/bin/env python3
"""
變異測試：驗證 typecheck.py 本身有效。

一個從不報錯的檢查器和沒有檢查器是一樣的，所以檢查器自己也要被測。
故意注入已知缺陷，確認每一個都被攔下，然後還原。

改用 Python 而非 shell：BSD sed 的 -i 需要備份字尾參數，
與 GNU sed 語法不同，在 macOS 上會噴 "extra characters at the end of l command"。
字串替換本來就不該依賴 sed。
"""
import pathlib
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent

MUTATIONS = [
    ('建構子具名參數打錯字', 'T1',
     'lib/features/crew_discovery/data/fake_crew_repository.dart',
     'activityScore: 0,', 'activitySore: 0,'),
    ('漏傳 required 參數', 'T2',
     'lib/features/crew_discovery/data/fake_crew_repository.dart',
     'locationName: d.locationName,', ''),
    ('static 成員不存在', 'T3',
     'lib/features/crew_discovery/presentation/filter_sheet.dart',
     'Space.lg', 'Space.huge'),
    ('Strings key 打錯字', 'T4',
     'lib/features/crew_discovery/presentation/filter_sheet.dart',
     's.filterClear', 's.filterClaer'),
    ('const 集合元素覆寫 ==', 'T8',
     'lib/features/crew_discovery/presentation/filter_sheet.dart',
     'setState(() => _draft = const CrewFilter())',
     'setState(() => _draft = const CrewFilter(styles: <StyleTag>{StyleTag.night}))'),
    # 目標選在 linkLine()：那裡的 u 是真正的區域變數（非 const 宣告）。
    # 注意不要選 signInWithLine()——那裡的 u 已改為 `const u = AppUser(...)`，
    # 加上 const 反而是合法的 Dart。
    ('const 引數是區域變數', 'T9',
     'lib/features/auth/data/fake_auth_repository.dart',
     'return Ok<AppUser>(u);\n  }\n\n  @override\n  Future<Result<AppUser>> completeExternalSignIn',
     'return const Ok<AppUser>(u);\n  }\n\n  @override\n  Future<Result<AppUser>> completeExternalSignIn'),
    # 真實案例：supabase_flutter 轉出的 gotrue Session 與 domain 的 Session 撞名。
    # 編譯器的錯誤訊息指向 domain 的 import 行，看起來像是我們的檔案有問題。
    ('第三方套件與專案型別撞名', 'T10',
     'lib/features/crew_discovery/data/supabase_crew_repository.dart',
     "import 'package:supabase_flutter/supabase_flutter.dart' as sb;",
     "import 'package:supabase_flutter/supabase_flutter.dart';"),
    ('pattern 解構欄位不存在', 'T5',
     'lib/features/crew_discovery/presentation/crew_list_controller.dart',
     'CrewListData(:final crews)', 'CrewListData(:final crewz)'),
]


def run_typecheck() -> str:
    r = subprocess.run([sys.executable, 'tool/typecheck.py'],
                       cwd=ROOT, capture_output=True, text=True)
    return r.stdout + r.stderr


def main() -> int:
    backup = pathlib.Path(tempfile.mkdtemp()) / 'lib'
    shutil.copytree(ROOT / 'lib', backup)
    passed = failed = 0
    print(f'變異測試 — 注入 {len(MUTATIONS)} 個已知缺陷')
    try:
        for desc, code, rel, old, new in MUTATIONS:
            target = ROOT / rel
            src = target.read_text()
            if old not in src:
                print(f'  ✗ 設定錯誤：{rel} 找不到 "{old}"')
                failed += 1
                continue
            target.write_text(src.replace(old, new, 1))
            hit = any(line.startswith(f'✗ {code}') for line in run_typecheck().splitlines())
            print(f'  {"✓ 攔截" if hit else "✗ 漏抓"}：{desc}（{code}）')
            passed, failed = (passed + 1, failed) if hit else (passed, failed + 1)
            shutil.rmtree(ROOT / 'lib')
            shutil.copytree(backup, ROOT / 'lib')
    finally:
        if (ROOT / 'lib').exists():
            shutil.rmtree(ROOT / 'lib')
        shutil.copytree(backup, ROOT / 'lib')
        shutil.rmtree(backup.parent)

    print(f'\n攔截 {passed} / 漏抓 {failed}')
    if failed:
        print('檢查器本身有盲點，需修正')
        return 1
    print('檢查器有效')
    return 0


if __name__ == '__main__':
    sys.exit(main())
