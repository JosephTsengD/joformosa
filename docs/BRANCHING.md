# 分支策略

## 兩條長期分支

```
main   ← 已上線的東西。每一個 commit 都對應線上正在跑的版本。
 ↑
dev    ← 整合中的東西。功能完成但還沒決定要不要上線。
 ↑
feat/* ← 單一任務。從 dev 切出，做完合回 dev。
```

**規則只有一條：`main` 永遠是可部署的。**

其他都是為了守住這條而存在的機制。

## 為什麼不直接推 main

你現在一個人開發，直接推 main 也能動。但這個專案的目的之一是展示
工程判斷，而「所有東西都直接進 production」在面試時很難解釋。

更實際的理由是：**你會需要一個可以放心弄壞的地方。**
接 Supabase、改資料模型、試新套件——這些事在 main 上做，
一旦中途卡住，你的線上網站就是壞的。

## 日常流程

```bash
# 一次性設定
git checkout -b dev
git push -u origin dev

# 每個任務
git checkout dev && git pull
git checkout -b feat/T-070-search

# ... 開發 ...
bash tool/harness.sh          # 本機先綠，不要浪費 CI 時間

git add -A
git commit -m "feat(search): 加入關鍵字搜尋與最近搜尋紀錄 (T-070)"
git push -u origin feat/T-070-search
gh pr create --base dev --fill
```

CI 綠了才合併。累積幾個功能、確認整體沒問題之後：

```bash
gh pr create --base main --head dev --title "release: v0.2.0"
```

合進 main 的那一刻，`deploy-web` 自動部署上線。

## commit 訊息格式

```
<type>(<scope>): <中文描述> (<task-id>)
```

| type | 用途 |
|---|---|
| `feat` | 新功能 |
| `fix` | 修 bug |
| `refactor` | 不改行為的重構 |
| `test` | 只動測試 |
| `docs` | 只動文件 |
| `chore` | 建置、設定、依賴 |

帶上 task id（`T-070`）讓 commit 能對回 `docs/tasks/` 的規格。
**面試時被問「你怎麼追蹤需求到實作」，這就是答案。**

## 分支保護（建議設定）

Settings → Branches → Add rule，對 `main`：

- ☑ Require a pull request before merging
- ☑ Require status checks to pass → 勾選 `static`、`test`
- ☑ Require branches to be up to date before merging

一個人開發時這看起來多餘，但它的價值在於**你無法在半夜三點手滑把壞東西推上線**。

## 為什麼 dev 不自動部署

GitHub Pages 一個 repo 只有一個站台。讓 dev 也部署等於直接覆蓋線上版本——
那 main 就沒有意義了。

真的需要預覽環境的話，用 Cloudflare Pages：它對每個 PR 自動產生獨立網址。
見 `docs/DEPLOY.md`。
