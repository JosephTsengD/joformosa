#!/usr/bin/env python3
"""
靜態自我審查 — 在沒有 Flutter SDK 的環境下，盡可能找出「一定會編譯失敗」的問題。

這不是 flutter analyze 的替代品，而是它的前哨。
涵蓋的錯誤類別（皆為 compile-blocker）：
  C1 括號 / 引號不平衡
  C2 相對 import 指向不存在的檔案
  C3 test 中的 package:joincrew/... import 指向不存在的檔案
  C4 使用了未 import 的跨檔案型別（啟發式，只查專案自訂型別）
  C5 宣告了但整個專案沒用到的 public 類別（死碼，非阻斷）
  C6 pubspec 宣告但未被 import 的依賴（非阻斷）
  C7 用到高版本 Flutter API 但 SDK 下限太低
  C8 widget test 觸發 context.go 卻沒有 router（執行期爆炸）
"""
import re, sys, pathlib, collections

ROOT = pathlib.Path('.')
LIB = ROOT / 'lib'
TEST = ROOT / 'test'
problems = collections.defaultdict(list)


def strip_code(src):
    """移除註解與字串內容，保留結構字元。"""
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == '/' and src[i+1:i+2] == '/':
            while i < n and src[i] != '\n':
                i += 1
        elif c == '/' and src[i+1:i+2] == '*':
            i += 2
            while i + 1 < n and not (src[i] == '*' and src[i+1] == '/'):
                i += 1
            i += 2
        elif c in '"\'':
            q = c
            if src[i:i+3] == q*3:
                i += 3
                while i + 2 < n and src[i:i+3] != q*3:
                    i += 2 if src[i] == '\\' else 1
                i += 3
            else:
                i += 1
                while i < n and src[i] != q:
                    if src[i] == '\\':
                        i += 1
                    elif src[i:i+2] == '${':
                        depth, i = 1, i+2
                        out.append('(')
                        while i < n and depth:
                            if src[i] == '{': depth += 1
                            elif src[i] == '}': depth -= 1
                            else: out.append(src[i] if src[i] in '()[]' else ' ')
                            i += 1
                        out.append(')')
                        continue
                    i += 1
                i += 1
        else:
            out.append(c)
            i += 1
    return ''.join(out)


dart_files = sorted(list(LIB.rglob('*.dart')) + list(TEST.rglob('*.dart')))

# ── C1 括號平衡 ──────────────────────────────────────────
for p in dart_files:
    s = strip_code(p.read_text())
    pairs = {'{': '}', '(': ')', '[': ']'}
    stack, line = [], 1
    for ch in s:
        if ch == '\n':
            line += 1
        if ch in pairs:
            stack.append((ch, line))
        elif ch in pairs.values():
            if not stack or pairs[stack[-1][0]] != ch:
                problems['C1'].append(f'{p}:{line} 非預期的 {ch!r}')
                break
            stack.pop()
    else:
        if stack:
            problems['C1'].append(f'{p} 第 {stack[-1][1]} 行的 {stack[-1][0]!r} 未閉合')

# ── C2 / C3 import 解析 ─────────────────────────────────
for p in dart_files:
    src = p.read_text()
    for m in re.finditer(r"import\s+'([^']+)'", src):
        path = m.group(1)
        if path.startswith('package:joincrew/'):
            target = LIB / path[len('package:joincrew/'):]
            key = 'C3'
        elif path.startswith(('dart:', 'package:')):
            continue
        else:
            target = (p.parent / path).resolve()
            key = 'C2'
        if not target.exists():
            problems[key].append(f'{p} → {path}（找不到檔案）')

# ── C4 未 import 的專案型別（啟發式）─────────────────────
declared = {}          # 型別名 -> 定義檔
for p in LIB.rglob('*.dart'):
    for m in re.finditer(r'^(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)*'
                         r'(?:class|enum|mixin|extension)\s+(\w+)', strip_code(p.read_text()), re.M):
        name = m.group(1)
        if not name.startswith('_'):
            declared.setdefault(name, p)

for p in dart_files:
    src = p.read_text()
    body = strip_code(src)
    imported = set()
    for m in re.finditer(r"import\s+'([^']+)'", src):
        path = m.group(1)
        if path.startswith('package:joincrew/'):
            imported.add((LIB / path[len('package:joincrew/'):]).resolve())
        elif not path.startswith(('dart:', 'package:')):
            imported.add((p.parent / path).resolve())
    self_declared = set(re.findall(
        r'^(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)*'
        r'(?:class|enum|mixin|extension)\s+(\w+)', src, re.M))
    used = set(re.findall(r'\b([A-Z]\w+)\b', body))
    for name in sorted(used):
        if name in self_declared or name not in declared:
            continue
        if declared[name].resolve() == p.resolve():
            continue
        if declared[name].resolve() not in imported:
            problems['C4'].append(f'{p} 使用 {name}，但未 import {declared[name]}')

# ── C5 死碼 ─────────────────────────────────────────────
all_src = '\n'.join(strip_code(p.read_text()) for p in dart_files)
raw_src = '\n'.join(p.read_text() for p in dart_files)
ext_names = set()
for p in LIB.rglob('*.dart'):
    ext_names |= set(re.findall(r'^extension\s+(\w+)', p.read_text(), re.M))
for name, src_file in sorted(declared.items()):
    if name in ext_names:
        continue          # extension 以成員名呼叫，名稱不會出現在使用端
    if len(re.findall(rf'\b{name}\b', all_src)) <= 1:
        problems['C5'].append(f'{name}（定義於 {src_file}）從未被使用')

# ── C6 未使用的依賴 ─────────────────────────────────────
pub = (ROOT / 'pubspec.yaml').read_text()
deps_block = pub.split('dev_dependencies:')[0]
for m in re.finditer(r'^  ([a-z_0-9]+):', deps_block, re.M):
    d = m.group(1)
    if d in ('flutter', 'sdk'):
        continue
    if f'package:{d}/' not in raw_src:
        problems['C6'].append(f'pubspec 宣告 {d} 但程式中從未 import')

# ── C7 Flutter API 版本需求 ─────────────────────────────
API_MIN = {
    r'\.withValues\(': ('Color.withValues', '3.27'),
    r'onPopInvokedWithResult': ('PopScope.onPopInvokedWithResult', '3.24'),
    r'SliverList\.separated': ('SliverList.separated', '3.13'),
    r'textScalerOf|TextScaler': ('TextScaler', '3.16'),
    r'InkSparkle': ('InkSparkle', '3.0'),
}
found = {}
for pat, (label, ver) in API_MIN.items():
    for p in dart_files:
        if re.search(pat, p.read_text()):
            found[label] = ver
            break
required = max(found.values(), key=lambda v: tuple(map(int, v.split('.')))) if found else '0.0'
sdk_line = re.search(r'sdk:\s*">=([\d.]+)', pub)
dart_to_flutter = {'3.6': '3.27', '3.5': '3.24', '3.4': '3.22', '3.3': '3.19'}
declared_flutter = dart_to_flutter.get(sdk_line.group(1)[:3], '?') if sdk_line else '?'
if declared_flutter != '?' and tuple(map(int, declared_flutter.split('.'))) < tuple(map(int, required.split('.'))):
    problems['C7'].append(
        f'程式需要 Flutter {required}（{", ".join(found)}），但 pubspec 下限只到 {declared_flutter}')

# ── C8 widget test 用到路由但沒有 router ────────────────
for p in TEST.rglob('*.dart'):
    src = p.read_text()
    screens = re.findall(r'home:\s*const\s+(\w+Screen)\(', src)
    for sc in screens:
        target = declared.get(sc)
        if target and re.search(r'context\.(go|push|pop)\(', target.read_text()):
            if 'MaterialApp.router' not in src and 'GoRouter' not in src:
                problems['C8'].append(
                    f'{p} 直接以 MaterialApp(home: {sc}) 掛載，但 {sc} 會呼叫 context.go()，'
                    f'測試執行時會拋 GoError')

# ── C9 未使用的專案 import ───────────────────────────────
# analyze 的 unused_import 是 warning，在 --fatal-infos 之下會讓 harness 失敗。
# 這裡只查專案內部的 import（第三方套件的符號表我們沒有），
# 判斷方式：該檔案匯出的公開型別名稱有沒有出現在使用端。
for p in dart_files:
    src = p.read_text()
    body = strip_code(''.join(l + '\n' for l in src.splitlines()
                         if not l.startswith('import ')))
    for line in src.splitlines():
        m = re.match(r"import\s+'([^']+)'\s*;\s*$", line)
        if not m:
            continue
        path = m.group(1)
        if path.startswith('package:joincrew/'):
            target = LIB / path[len('package:joincrew/'):]
        elif path.startswith(('dart:', 'package:')):
            continue
        else:
            target = (p.parent / path)
        if not target.exists():
            continue
        tsrc = target.read_text()
        # 要抓齊三類頂層宣告，少一類就會產生誤判：
        #   class / enum / mixin / extension
        #   頂層函式（sportIcon、sportLabel）
        #   頂層變數，含無型別的 final（final adminProvider = ...）
        names = set(re.findall(
            r'^(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)*'
            r'(?:class|enum|mixin|extension)\s+(\w+)', tsrc, re.M))
        names |= set(re.findall(r'^(?:final|const|var|late)\s+(?:[\w<>,?\[\]\s]+?\s+)?(\w+)\s*=',
                                tsrc, re.M))
        names |= set(re.findall(r'^[\w<>,?\[\]]+\s+(\w+)\s*[(<]', tsrc, re.M))
        names = {n for n in names if not n.startswith('_')}
        if not names:
            continue
        # extension 是隱式使用（context.colors），無法用名稱判斷
        if re.search(r'^extension\s', target.read_text(), re.M):
            continue
        if not any(re.search(rf'\b{n}\b', body) for n in names):
            problems['C9'].append(f'{p} → {path} 沒有用到任何東西')

# ── 輸出 ────────────────────────────────────────────────
LABEL = {
  'C1': ('BLOCKER', '括號 / 引號不平衡'),
  'C2': ('BLOCKER', '相對 import 找不到檔案'),
  'C3': ('BLOCKER', 'test 的 package import 找不到檔案'),
  'C4': ('BLOCKER', '使用未 import 的專案型別'),
  'C5': ('MINOR',   '死碼'),
  'C6': ('MINOR',   '未使用的依賴'),
  'C7': ('BLOCKER', 'SDK 版本下限過低'),
  'C8': ('BLOCKER', '測試會在執行期拋錯'),
  # 非阻斷：flutter analyze 的 unused_import 才是權威，
  # 這裡只是在沒有 analyzer 的環境提供早期提示。
  'C9': ('MINOR', '未使用的專案 import'),
}
blockers = 0
print(f'掃描 {len(dart_files)} 個 Dart 檔\n')
for key in sorted(LABEL):
    sev, desc = LABEL[key]
    hits = problems.get(key, [])
    mark = '✓' if not hits else ('✗' if sev == 'BLOCKER' else '!')
    print(f'{mark} {key} {desc:<28} {len(hits)} 項')
    for h in hits[:12]:
        print(f'      {h}')
    if len(hits) > 12:
        print(f'      …另外 {len(hits)-12} 項')
    if hits and sev == 'BLOCKER':
        blockers += len(hits)
print()
print('PASSED' if blockers == 0 else f'FAILED — {blockers} 個 blocker')
sys.exit(0 if blockers == 0 else 1)
