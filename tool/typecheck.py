#!/usr/bin/env python3
"""
迷你型別檢查器 — 在沒有 Dart analyzer 的環境下，驗證專案自訂型別的使用是否正確。

它不是 analyzer 的替代品，而是針對「最容易出錯、且一定編譯失敗」的幾類問題：

  T1  建構子具名參數不存在（打錯字）
  T2  建構子的 required 參數漏傳
  T3  static / enum 成員不存在（Space.xxx、City.xxx、Sport.xxx）
  T4  Strings 字典的 key 不存在（s.xxx / strings.xxx）
  T5  pattern 解構的欄位在該類別上不存在（Case(:final foo)）
  T6  implements 的類別沒有實作介面的全部成員
  T7  sealed 類別的 switch 沒有窮盡所有子型別

範圍限定在專案自己宣告的型別。Flutter / Dart SDK 的型別不在檢查範圍內
（那需要完整的 SDK 型別資訊），由 flutter analyze 負責。
"""
import re
import sys
import pathlib
import collections

ROOT = pathlib.Path('.')
LIB = ROOT / 'lib'
TEST = ROOT / 'test'
problems = collections.defaultdict(list)


# ── 前處理：移除註解與字串內容 ────────────────────────────
def strip_code(src: str) -> str:
    out, i, n = [], 0, len(src)
    while i < n:
        c = src[i]
        if c == '/' and src[i + 1:i + 2] == '/':
            while i < n and src[i] != '\n':
                out.append('\n' if src[i] == '\n' else ' ')
                i += 1
        elif c == '/' and src[i + 1:i + 2] == '*':
            while i + 1 < n and not (src[i] == '*' and src[i + 1] == '/'):
                out.append('\n' if src[i] == '\n' else ' ')
                i += 1
            out.append('  ')
            i += 2
        elif c in '"\'':
            q = c
            if src[i:i + 3] == q * 3:
                i += 3
                out.append('""')
                while i + 2 < n and src[i:i + 3] != q * 3:
                    out.append('\n' if src[i] == '\n' else ' ')
                    i += 1
                i += 3
            else:
                i += 1
                out.append('"')
                while i < n and src[i] != q:
                    if src[i] == '\\':
                        i += 2
                        continue
                    if src[i:i + 2] == '${':
                        depth, i = 1, i + 2
                        out.append(' ')
                        while i < n and depth:
                            if src[i] == '{':
                                depth += 1
                            elif src[i] == '}':
                                depth -= 1
                            else:
                                out.append(src[i])
                            i += 1
                        continue
                    out.append(' ')
                    i += 1
                out.append('"')
                i += 1
        else:
            out.append(c)
            i += 1
    return ''.join(out)


def match_paren(s: str, start: int, open_ch='(', close_ch=')'):
    """start 指向 open_ch，回傳 (內容, close 索引)。"""
    depth, i, n = 0, start, len(s)
    while i < n:
        if s[i] in '([{':
            depth += 1
        elif s[i] in ')]}':
            depth -= 1
            if depth == 0:
                return s[start + 1:i], i
        i += 1
    return None, -1


def split_top(s: str) -> list:
    """以 depth 0 的逗號切分。

    注意：不能把 `<` `>` 當括號——Dart 的箭頭函式 `=>` 會讓 depth 變負，
    整個參數列就被切錯。泛型的逗號寧可多切一刀，也不要少切。
    """
    s = s.replace('=>', '= ').replace('>=', ' =').replace('<=', '= ')
    out, depth, cur = [], 0, []
    for ch in s:
        if ch in '([{':
            depth += 1
        elif ch in ')]}':
            depth -= 1
        if ch == ',' and depth == 0:
            out.append(''.join(cur))
            cur = []
        else:
            cur.append(ch)
    if ''.join(cur).strip():
        out.append(''.join(cur))
    return [x.strip() for x in out if x.strip()]


def line_of(src: str, idx: int) -> int:
    return src.count('\n', 0, idx) + 1


# ── 第一階段：建立專案型別索引 ────────────────────────────
CLASS_RE = re.compile(
    r'^(?P<mods>(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+|mixin\s+)*)'
    r'(?P<kind>class|enum)\s+(?P<name>\w+)'
    r'(?P<generics><[^>]*>)?'
    r'(?P<clauses>[^{]*)\{', re.M)

classes = {}   # name -> dict
files = sorted(list(LIB.rglob('*.dart')) + list(TEST.rglob('*.dart')))
stripped = {p: strip_code(p.read_text()) for p in files}

for p in files:
    src = stripped[p]
    for m in CLASS_RE.finditer(src):
        name = m.group('name')
        body, end = match_paren(src, m.end() - 1, '{', '}')
        if body is None:
            continue
        clauses = m.group('clauses') or ''
        extends = re.search(r'extends\s+(\w+)', clauses)
        implements = re.findall(r'\w+', re.search(r'implements\s+([^{]*)', clauses).group(1)) \
            if 'implements' in clauses else []
        classes[name] = {
            'file': p,
            'line': line_of(src, m.start()),
            'kind': m.group('kind'),
            'sealed': 'sealed' in m.group('mods'),
            'abstract': 'abstract' in m.group('mods'),
            'body': body,
            'extends': extends.group(1) if extends else None,
            'implements': implements,
            'ctors': {},
            'members': set(),
            'statics': set(),
            'enum_values': set(),
        }

# 成員與建構子
for name, c in classes.items():
    body = c['body']

    if c['kind'] == 'enum':
        head = body.split(';')[0]
        for v in split_top(head):
            vn = re.match(r'(\w+)', v)
            if vn:
                c['enum_values'].add(vn.group(1))
        c['enum_values'] |= {'values', 'name', 'index'}

    # 欄位：final Type name; / static const Type name = ...
    for m in re.finditer(r'(static\s+)?(?:final|const|late\s+final|late)\s+'
                         r'(?:[\w<>,?\s\[\]]+\s+)?(\w+)\s*(?:=|;)', body):
        target = c['statics'] if m.group(1) else c['members']
        target.add(m.group(2))
    # getter
    for m in re.finditer(r'(static\s+)?[\w<>,?\s\[\]]+\s+get\s+(\w+)', body):
        (c['statics'] if m.group(1) else c['members']).add(m.group(2))
    # 方法
    for m in re.finditer(r'(static\s+)?[\w<>,?\s\[\]]+\s+(\w+)\s*(?:<[^>]*>)?\s*\(', body):
        nm = m.group(2)
        if nm in ('if', 'for', 'while', 'switch', 'return', 'catch', 'assert', name):
            continue
        (c['statics'] if m.group(1) else c['members']).add(nm)
    # 建構子（含 const / named）
    # 只接受「宣告」：前一個非空白字元必須是 { } ; 之一，
    # 否則會抓到 `= AppColors(` / `return Crew(` 這種呼叫端，
    # 並在迴圈中覆蓋掉真正的建構子定義。
    for m in re.finditer(r'(?:^|\s)(?:const\s+)?' + re.escape(name) + r'(?:\.(\w+))?\s*\(', body):
        prev = body[:m.start()].rstrip()
        if prev and prev[-1] not in '{};':
            continue
        open_idx = body.index('(', m.end() - 1)
        params, _ = match_paren(body, open_idx)
        if params is None:
            continue
        named, required, positional = {}, set(), 0
        nb = re.search(r'\{', params)
        named_src = ''
        if nb:
            named_src, _ = match_paren(params, nb.start(), '{', '}')
            positional_src = params[:nb.start()]
        else:
            positional_src = params
        for e in split_top(named_src or ''):
            pm = re.search(r'(\w+)\s*(?:=|$)', e.split('=')[0].strip())
            if pm:
                pn = pm.group(1)
                named[pn] = True
                if e.strip().startswith('required'):
                    required.add(pn)
        positional = len([e for e in split_top(positional_src) if e])
        c['ctors'][m.group(1) or ''] = {
            'named': set(named), 'required': required, 'positional': positional,
        }
        # this.x / super.x 也是成員
        for pm in re.finditer(r'this\.(\w+)', params):
            c['members'].add(pm.group(1))


def all_members(name, seen=None):
    seen = seen or set()
    if name in seen or name not in classes:
        return set()
    seen.add(name)
    c = classes[name]
    out = set(c['members']) | set(c['enum_values'])
    if c['extends']:
        out |= all_members(c['extends'], seen)
    for i in c['implements']:
        out |= all_members(i, seen)
    return out


def find_ctor(name):
    """沿著繼承鏈找建構子。"""
    c = classes.get(name)
    if not c:
        return None
    if '' in c['ctors']:
        return c['ctors']['']
    return None


# ── T1 / T2 建構子呼叫檢查 ────────────────────────────────
SKIP_ARGS = {'key', 'child', 'children'}
for p in files:
    src = stripped[p]
    for name, c in classes.items():
        if c['kind'] == 'enum' or c['abstract']:
            continue
        ctor = find_ctor(name)
        if ctor is None:
            continue
        for m in re.finditer(r'(?<![\w.])' + re.escape(name) + r'\s*\(', src):
            args, _ = match_paren(src, m.end() - 1)
            if args is None:
                continue
            # 建構子「宣告」的參數列一定含 `this.` 或 `required`，
            # 呼叫端永遠不會——用這個區分，避免把宣告當成呼叫來檢查。
            if re.search(r'\bthis\.|\brequired\b|\bsuper\.', args):
                continue
            # pattern 解構 `CrewListData(:final crews)` 不是建構子呼叫，
            # 由 T5 負責檢查其欄位是否存在。
            if re.search(r':\s*(final|var)\s+\w+', args):
                continue
            given = set()
            for e in split_top(args):
                am = re.match(r'(\w+)\s*:', e)
                if am:
                    given.add(am.group(1))
            unknown = given - ctor['named'] - SKIP_ARGS
            for u in sorted(unknown):
                problems['T1'].append(
                    f'{p}:{line_of(src, m.start())} {name}(...) 不存在具名參數 `{u}`')
            if given or ctor['positional'] == 0:
                missing = ctor['required'] - given
                for miss in sorted(missing):
                    problems['T2'].append(
                        f'{p}:{line_of(src, m.start())} {name}(...) 漏傳 required 參數 `{miss}`')

# ── T3 static / enum 成員存取 ─────────────────────────────
for p in files:
    src = stripped[p]
    for m in re.finditer(r'(?<![\w.])([A-Z]\w+)\.(\w+)', src):
        tn, mem = m.group(1), m.group(2)
        c = classes.get(tn)
        if not c:
            continue
        valid = c['statics'] | c['enum_values']
        if c['kind'] == 'enum':
            valid |= {'values', 'byName'}
        else:
            valid |= {'new'}
        # 建構子名稱也合法
        valid |= {k for k in c['ctors'] if k}
        if mem not in valid and mem not in c['members']:
            problems['T3'].append(
                f'{p}:{line_of(src, m.start())} {tn} 沒有 static/enum 成員 `{mem}`')

# ── T4 Strings 字典 key ───────────────────────────────────
if 'Strings' in classes:
    keys = all_members('Strings')
    for p in files:
        src = stripped[p]
        for m in re.finditer(r'(?<![\w.])(?:s|str|strings|widget\.strings)\.(\w+)', src):
            k = m.group(1)
            if k in keys:
                continue
            # 只在該檔案確實用到 Strings 時才判定
            if 'Strings' not in src and 'stringsProvider' not in src:
                continue
            problems['T4'].append(
                f'{p}:{line_of(src, m.start())} Strings 沒有 `{k}`')

# ── T5 pattern 解構欄位 ───────────────────────────────────
for p in files:
    src = stripped[p]
    for m in re.finditer(r'(?<![\w.])([A-Z]\w+)(?:<[^>]*>)?\s*\(\s*((?::\s*final\s+\w+\s*,?\s*)+)\)', src):
        tn = m.group(1)
        if tn not in classes:
            continue
        mems = all_members(tn)
        for fm in re.finditer(r':\s*final\s+(\w+)', m.group(2)):
            if fm.group(1) not in mems:
                problems['T5'].append(
                    f'{p}:{line_of(src, m.start())} {tn} 沒有欄位 `{fm.group(1)}`（pattern 解構）')

# ── T6 implements 完整性 ──────────────────────────────────
for name, c in classes.items():
    for iface in c['implements']:
        ic = classes.get(iface)
        if not ic or not (ic['abstract'] or 'interface' in str(ic)):
            continue
        # 介面中「宣告但無實作」的成員
        abstract_members = set()
        for m in re.finditer(r'^\s*(?:[\w<>,?\s\[\]]+)\s+(\w+)\s*\([^)]*\)\s*;', ic['body'], re.M):
            abstract_members.add(m.group(1))
        for m in re.finditer(r'^\s*[\w<>,?\s\[\]]+\s+get\s+(\w+)\s*;', ic['body'], re.M):
            abstract_members.add(m.group(1))
        have = all_members(name)
        for miss in sorted(abstract_members - have):
            problems['T6'].append(
                f'{c["file"]} {name} implements {iface}，但未實作 `{miss}`')

# ── T7 sealed switch 窮盡性 ───────────────────────────────
subtypes = collections.defaultdict(set)
for name, c in classes.items():
    if c['extends'] and classes.get(c['extends'], {}).get('sealed'):
        subtypes[c['extends']].add(name)

PATTERN_HEAD = re.compile(r'(?:case\s+|^\s*|,\s*)(\w+)\s*(?:<[^>]*>)?\s*\([^()]*\)\s*(?:=>|:|when\b)', re.M)

for p in files:
    src = stripped[p]
    for m in re.finditer(r'switch\s*\(', src):
        body_start = src.find('{', m.end())
        if body_start < 0:
            continue
        body, _ = match_paren(src, body_start, '{', '}')
        if body is None:
            continue
        if re.search(r'(^|\s)_\s*(=>|:)', body) or 'default' in body:
            continue
        # 只看 case pattern 的頭型別，不看 body 中被建構的型別
        heads = {h.group(1) for h in PATTERN_HEAD.finditer(body)}
        for base, subs in subtypes.items():
            covered = heads & subs
            if len(covered) < 2 or covered == subs:
                continue
            for miss in sorted(subs - covered):
                problems['T7'].append(
                    f'{p}:{line_of(src, m.start())} switch({base}) 未涵蓋 `{miss}`')

# ── T8 const 集合／Map key 的元素型別覆寫 == ──────────────
# Dart 規則：常數集合要在編譯期去重，而自訂的 == 編譯期算不出來，
# 因此元素型別不得覆寫 ==（const_set_element_type_implements_equals）。
# 這是最容易寫出來、又只有編譯器才抓得到的一類錯誤。
eq_overriders = {
    n for n, c in classes.items()
    if re.search(r'bool\s+operator\s*==', c['body'])
}
def _flag_const_set(path, src, offset, region):
    """在單一 const 運算式的範圍內尋找非空的具型別集合字面值。"""
    for sm in re.finditer(r'<\s*(\w+)\s*>\s*\{([^{}]*)\}', region):
        tn, inner = sm.group(1), sm.group(2)
        if tn in eq_overriders and inner.strip():
            problems['T8'].append(
                f'{path}:{line_of(src, offset)} const 集合的元素型別 `{tn}` '
                f'覆寫了 ==，Dart 不允許。移除該處的 const 即可')
            return


for p in files:
    src = stripped[p]
    # ① const ClassName(...) —— const 會傳染到整個引數列
    # 同時涵蓋 `const Foo(...)` 與 `const x = Foo(...)` 兩種寫法
    for m in re.finditer(r'\bconst\s+(?:\w+\s*=\s*)?\w+\s*\(', src):
        args, _ = match_paren(src, m.end() - 1)
        if args:
            _flag_const_set(p, src, m.start(), args)
    # ② const <T>{...} 直接寫成常數集合
    for m in re.finditer(r'\bconst\s*<\s*\w+\s*>\s*\{[^{}]*\}', src):
        _flag_const_set(p, src, m.start(), m.group(0))

# ── T9 const 建構子的引數不是編譯期常數 ──────────────────
# `const Ok<AppUser>(u)` 其中 u 是區域變數 → Not a constant expression。
# 即使 u 以 const 運算式初始化，**變數本身**仍不是編譯期常數。
# 這類錯誤只有編譯器抓得到，而且寫起來完全自然。
LITERALS = {'null', 'true', 'false'}

# 專案層級的常數（top-level const 與 static const），這些永遠可用於 const 情境
global_consts = set()
for p in files:
    raw = stripped[p]
    global_consts |= set(re.findall(r'^\s*(?:static\s+)?const\s+(?:[\w<>,?\s]+\s+)?(\w+)\s*=',
                                    raw, re.M))


def _declared_const_before(src: str, name: str, pos: int) -> bool:
    """往回找該識別字最近的一次宣告，判斷它是不是 const。

    不能只用全域集合：同一個檔案裡可能有兩個同名區域變數，
    一個宣告為 const、另一個是 final。只看名字會把後者也放行。
    """
    last = None
    for m in re.finditer(r'\b(const|final|var|late)\s+(?:[\w<>,?\s]+\s+)?'
                         + re.escape(name) + r'\s*=', src[:pos]):
        last = m.group(1)
    return last == 'const'


for p in files:
    src = stripped[p]
    for m in re.finditer(r'\bconst\s+\w+\s*(?:<[^>]*>)?\s*\(', src):
        args, _ = match_paren(src, src.index('(', m.end() - 1))
        if not args:
            continue
        for entry in split_top(args):
            value = entry.split(':', 1)[1] if re.match(r'^\w+\s*:', entry) else entry
            value = value.strip()
            if not re.fullmatch(r'[a-z_]\w*', value) or value in LITERALS:
                continue
            if value in global_consts and _declared_const_before(src, value, m.start()):
                continue
            if _declared_const_before(src, value, m.start()):
                continue
            problems['T9'].append(
                f'{p}:{line_of(src, m.start())} const 建構子的引數 `{value}` '
                f'不是編譯期常數 —— 移除此處的 const')

# ── T10 第三方套件與專案型別撞名 ──────────────────────────
# 真實案例：supabase_flutter 轉出 gotrue 的 Session，與本專案 domain 的
# Session 直接衝突：
#   Error: 'Session' is imported from both 'package:gotrue/...' and 'package:joincrew/...'
#
# 這類錯誤在加入新依賴時才會浮現，而且訊息出現在「無辜」的那一行
# （指向 domain 的 import，而不是真正衝突的第三方 import），很難第一眼看懂。
#
# 解法一律是前綴 import。這裡只維護會撞到的名稱，不需要完整的套件符號表。
THIRD_PARTY_EXPORTS = {
    'supabase_flutter': {
        'Session', 'User', 'Provider', 'AuthState', 'AuthException',
        'Notifier', 'Query', 'Bucket', 'Factor',
    },
    'flutter_riverpod': {'Provider', 'Notifier', 'Family', 'Override'},
    'go_router': {'Route', 'RouteMatch'},
}

for p in files:
    src = stripped[p]
    raw = p.read_text()
    # 這個檔案的作用域裡有哪些專案型別？（自己宣告的 + import 進來的）
    in_scope = set(re.findall(
        r'^(?:abstract\s+|final\s+|sealed\s+|base\s+|interface\s+)*'
        r'(?:class|enum|mixin)\s+(\w+)', src, re.M))
    for m in re.finditer(r"import\s+'([^']+)'", raw):
        path = m.group(1)
        target = None
        if path.startswith('package:joincrew/'):
            target = (LIB / path[len('package:joincrew/'):]).resolve()
        elif not path.startswith(('dart:', 'package:')):
            target = (p.parent / path).resolve()
        if target is None:
            continue
        in_scope |= {n for n, c in classes.items() if c['file'].resolve() == target}

    for line in raw.splitlines():
        im = re.match(r"\s*import\s+'package:([a-z_0-9]+)/[^']*'(.*)", line)
        if not im:
            continue
        pkg, tail = im.group(1), im.group(2)
        if pkg not in THIRD_PARTY_EXPORTS:
            continue
        # 有前綴或 hide/show 就安全
        if ' as ' in tail or 'hide ' in tail or 'show ' in tail:
            continue
        clash = THIRD_PARTY_EXPORTS[pkg] & in_scope
        for name in sorted(clash):
            problems['T10'].append(
                f'{p} 無前綴 import {pkg}，其匯出的 `{name}` 與專案型別撞名'
                f' —— 改用 `as` 前綴')

# ── 輸出 ──────────────────────────────────────────────────
LABEL = {
    'T1': 'BLOCKER  建構子具名參數不存在',
    'T2': 'BLOCKER  漏傳 required 參數',
    'T3': 'BLOCKER  static/enum 成員不存在',
    'T4': 'BLOCKER  Strings key 不存在',
    'T5': 'BLOCKER  pattern 解構欄位不存在',
    'T6': 'BLOCKER  implements 未實作完整',
    'T7': 'BLOCKER  sealed switch 未窮盡',
    'T8': 'BLOCKER  const 集合元素覆寫 ==',
    'T9': 'BLOCKER  const 引數非編譯期常數',
    'T10': 'BLOCKER 第三方套件與專案型別撞名',
}
print(f'型別檢查：{len(classes)} 個專案型別，{len(files)} 個檔案\n')
total = 0
for k in sorted(LABEL):
    hits = problems.get(k, [])
    total += len(hits)
    print(f'{"✓" if not hits else "✗"} {k} {LABEL[k]:<34} {len(hits)} 項')
    for h in hits[:15]:
        print(f'      {h}')
    if len(hits) > 15:
        print(f'      …另外 {len(hits) - 15} 項')
print()
print('PASSED' if total == 0 else f'FAILED — {total} 個問題')
sys.exit(0 if total == 0 else 1)
