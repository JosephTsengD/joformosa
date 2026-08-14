# 在你的 Mac 上跑起來（5 分鐘）

## 1. 建立平台資料夾

這個壓縮檔只包含 `lib/`、`test/`、`supabase/` 等**原始碼**，
不含 `android/` `ios/` `web/` 這些由 Flutter 產生的平台專案
（它們有數百個檔案，且與你的本機環境綁定）。

```bash
unzip joincrew.zip && cd joincrew

# 讓 Flutter 產生平台資料夾（不會覆蓋既有的 lib/ 與 pubspec.yaml）
flutter create . --org tw.joincrew --project-name joincrew \
  --platforms=android,ios,web

flutter pub get
flutter run          # 或 flutter run -d chrome
```

`flutter create .` 在既有目錄執行時只補齊缺少的平台檔案。
若它動到 `pubspec.yaml`，用 `git diff` 檢查並還原即可。

## 2. 驗證品質閘門

```bash
bash tool/harness.sh --fast
```

第一次跑可能會有 `dart format` 的差異（我在容器中無法執行 formatter），
直接 `dart format .` 後再跑一次即可。

## 3. 需要的版本

- Flutter **3.27 或以上**（用到 `Color.withValues` 與 `PopScope.onPopInvokedWithResult`）
- 檢查：`flutter --version`
- 建議用 FVM 鎖版本：`fvm install 3.27.0 && fvm use 3.27.0`

## 4. 建立 GitHub repo

```bash
git init && git add -A
git commit -m "feat: initial JoinCrew skeleton with AI workflow harness"
gh repo create joincrew --public --source=. --push
```

CI 會自動跑 `.github/workflows/ci.yml`。

## 5. 接上 LINE 登入（需要時）

1. 到 LINE Developers Console 建立 Provider 與 **LINE Login channel**
2. Callback URL 填 `joincrew://login-callback`（與 `env/dev.json` 的
   `LINE_CALLBACK_SCHEME` 一致）
3. 部署 Edge Function：
   ```bash
   supabase functions deploy line-auth --no-verify-jwt
   supabase secrets set LINE_CHANNEL_ID=xxx LINE_CHANNEL_SECRET=yyy
   ```
4. 在 `pubspec.yaml` 啟用 `flutter_web_auth_2`，
   把 `FakeAuthRepository` 換成真實實作（`lib/features/auth/data/`）

**channel secret 絕對不可以進 App 或 git。** 理由見 `docs/adr/007`。
