# 第 0 步：安裝 Flutter 環境（macOS）

**先讀這份,再讀 `RUNBOOK.md`。** 這份只做一件事:讓 `flutter doctor` 能跑起來。
專案本身完全不碰。

預計 30–50 分鐘,大部分時間在等下載。

---

## 你需要知道的三件事

**一、Flutter SDK 就是一個資料夾。**
沒有安裝程式、不寫入系統目錄、不需要 root。它是一包工具,解壓縮到某個位置,
再把裡面的 `bin/` 加進 `PATH`,就這樣。要移除就把資料夾刪掉。

**二、Flutter 內含 Dart。**
不需要另外裝 Dart。裝了反而容易搞混版本 —— `which dart` 指到 Homebrew 的
那一份而不是 Flutter 內建的,是新手最常見的鬼打牆。

**三、`flutter doctor` 不需要全綠。**
它會列出所有平台的狀態。你只想跑 Web,就只要 Flutter 和 Chrome 兩項是綠的。
新手最常浪費的時間,就是想把 Android 那項也弄成綠勾 —— 那要 15 GB 的下載。

---

## 選一條路

| | 方法 A:FVM | 方法 B:官方 zip | 方法 C:Homebrew |
|---|---|---|---|
| 多專案不同版本 | ✅ 可以 | ❌ 全域一份 | ❌ 全域一份 |
| 升級控制權 | ✅ 你決定 | ✅ 你決定 | ⚠️ 可能被 `brew upgrade` 動到 |
| 步驟數 | 中 | 中 | 少 |

**建議方法 A。** 你會接觸不同專案,而 Flutter 版本差一個大版就編不過 ——
方法 C 的風險是你某天 `brew upgrade` 別的東西,順手把 Flutter 也升了,
然後某個專案突然壞掉,而你不知道為什麼。

急著看到畫面的話用方法 C,五分鐘。之後隨時可以換。

---

## 前置:Xcode Command Line Tools

三種方法都需要(git 在裡面)。

```bash
xcode-select --install
```

跳出視窗就按安裝。已經裝過會說 `already installed`,那是正常的。

Apple Silicon(M1/M2/M3/M4)還要裝 Rosetta,某些工具鏈仍是 x86:

```bash
sudo softwareupdate --install-rosetta --agree-to-license
```

Intel Mac 跳過這步。不確定自己是哪種?

```bash
uname -m
# arm64 = Apple Silicon,需要 Rosetta
# x86_64 = Intel,跳過
```

---

## 方法 A:FVM(建議)

```bash
# 1. 裝 Homebrew(已經有就跳過)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. 裝 FVM
brew tap leoafarias/fvm
brew install fvm

# 3. 裝 Flutter(這步會下載約 1 GB,慢是正常的)
fvm install stable
fvm global stable
```

把 FVM 的全域路徑加進 `PATH`:

```bash
echo 'export PATH="$HOME/fvm/default/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

用的是 bash 不是 zsh 的話,把 `~/.zshrc` 換成 `~/.bash_profile`。
不確定的話:`echo $SHELL`。

驗證:

```bash
flutter --version
```

要看到 `Flutter 3.44.x`(2026 年 8 月的最新穩定版)或更高。

之後在專案資料夾裡可以鎖版本:

```bash
cd joformosa
fvm use stable      # 產生 .fvmrc,團隊成員版本一致
```

---

## 方法 B:官方 zip

想完全掌控、不依賴 Homebrew 就選這個。

1. 開 <https://docs.flutter.dev/install/manual>
2. 選 macOS,再選你的晶片(**Apple Silicon** 或 **Intel**)—— 選錯會很慢或跑不動
3. 下載後解壓縮到家目錄:

```bash
mkdir -p ~/development
cd ~/development
unzip ~/Downloads/flutter_macos_arm64_*.zip     # 檔名依你下載的版本

echo 'export PATH="$HOME/development/flutter/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

flutter --version
```

⚠️ **不要解壓縮到這些位置:**

- `/usr/local/bin` 或任何需要 sudo 的路徑 —— 升級時會出權限問題
- 路徑含空白或中文的資料夾(例如 `~/我的專案/`)—— 建置腳本會出錯
- iCloud 同步的資料夾(桌面、文件)—— 檔案被抽走會導致詭異錯誤

---

## 方法 C:Homebrew(最快)

```bash
brew install --cask flutter
flutter --version
```

`flutter` 指令找不到的話:

```bash
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc   # Apple Silicon
# Intel 用 /usr/local/bin
source ~/.zshrc
```

---

## 第一次健檢

```bash
flutter doctor
```

第一次跑會下載額外工具,等一下。輸出大概像:

```
[✓] Flutter (Channel stable, 3.44.7, on macOS ...)
[✗] Android toolchain - develop for Android devices
[✗] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[✓] Network resources
```

**這樣就夠了。** Flutter 綠、Chrome 綠 → 可以跑這個專案的 Web 版。
Android 和 Xcode 的紅叉現在完全不影響。

只有這兩種情況需要處理:

| 狀況 | 意思 | 處理 |
|---|---|---|
| `[✗] Flutter` | SDK 本身有問題 | 見下方疑難排解 |
| `[✗] Chrome` | 找不到 Chrome | 裝 Google Chrome 即可 |

---

## 加裝平台(想跑手機才需要)

### iOS(只有 Mac 能做)

```bash
# 1. App Store 搜尋 Xcode 安裝 —— 約 15 GB,建議晚上掛著
# 2. 裝完後執行這三行
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept

# 3. CocoaPods(iOS 的套件管理)
sudo gem install cocoapods

# 4. 開模擬器
open -a Simulator
```

⚠️ Flutter 3.38 之後完整支援 iOS 26 / Xcode 26。Xcode 版本太舊會有奇怪的建置錯誤,
遇到就先把 Xcode 更新到最新。

### Android

1. 裝 [Android Studio](https://developer.android.com/studio)
2. 第一次開啟走完 Setup Wizard(它會自動下載 SDK)
3. 接受授權:

```bash
flutter doctor --android-licenses
# 一直按 y 直到結束
```

4. 建模擬器:Android Studio → Device Manager → Create Device → Pixel 7 → API 34

---

## 編輯器

擇一即可。

**VS Code**(輕、開得快):

```bash
brew install --cask visual-studio-code
```

裝完在 VS Code 裡按 `Cmd+Shift+X`,搜尋並安裝 **Flutter** 擴充套件
(它會自動附帶 Dart)。

**Android Studio**(重、功能全,Android 開發較方便):
Preferences → Plugins → 搜尋 Flutter → Install。

兩個都裝了同一份 SDK,可以混用。

---

## 完成檢查

四行都成功就可以進 `RUNBOOK.md` 了:

```bash
flutter --version           # 顯示 3.27 以上(建議 3.44.x)
flutter doctor              # Flutter 與 Chrome 為綠勾
dart --version              # 內建的 Dart,不需另外安裝
flutter devices             # 至少列出 Chrome
```

想確認整個工具鏈真的能建置,可以拿一個空專案試:

```bash
cd /tmp
flutter create hello_flutter
cd hello_flutter
flutter run -d chrome
```

看到計數器 App 就代表環境沒問題。這一步很值得做 ——
**先確認環境是好的,之後再遇到錯誤,你就知道問題出在專案而不是環境。**
確認完可以刪掉:`rm -rf /tmp/hello_flutter`。

---

## 疑難排解

| 現象 | 原因 | 解法 |
|---|---|---|
| `command not found: flutter` | PATH 沒生效 | `source ~/.zshrc`,或重開終端機 |
| `which flutter` 指到奇怪的位置 | 裝了不只一份 | `brew uninstall --cask flutter` 留一份就好 |
| `Waiting for another flutter command to release the startup lock` | 前次指令沒正常結束 | `killall -9 dart` 後重試 |
| `flutter doctor` 卡在 Network resources | 網路或需要代理 | 換網路試,或設 `FLUTTER_STORAGE_BASE_URL` |
| `Unable to find bundled Java` | Android Studio 版本問題 | `flutter config --jdk-dir=$(/usr/libexec/java_home)` |
| `CocoaPods not installed` | 只影響 iOS | 只跑 Web 的話可以忽略 |
| 下載極慢 | 中國網路環境 | 用鏡像站,見下方 |
| `Xcode installation is incomplete` | 只裝了 CLT 沒裝 Xcode | 只跑 Web 的話可以忽略 |

**下載很慢時**(台灣通常不需要,但列著備用):

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

**想完全重來:**

```bash
rm -rf ~/development/flutter          # 方法 B
brew uninstall --cask flutter         # 方法 C
fvm remove stable                     # 方法 A
# 再把 ~/.zshrc 裡相關的 export PATH 那行刪掉
```

---

## 下一步

環境好了,接 [`RUNBOOK.md`](RUNBOOK.md) 的 Part 3。

它的第一步是 `flutter create . --platforms=android,ios,web` ——
壓縮檔裡只有原始碼,平台資料夾要在**你的環境**現場產生,才會版本相容。

---

## 附錄：Apple Silicon + VS Code + Claude Code

### 為什麼建議 VS Code 而不是 Android Studio

| | VS Code | Android Studio |
|---|---|---|
| Flutter 官方支援 | 一樣好（同一個 Dart-Code 團隊維護） | 一樣好 |
| Claude Code 整合 | ✅ 官方擴充 | ✅ JetBrains 擴充 |
| 冷啟動 | 2–3 秒 | 20–40 秒 |
| 記憶體 | 約 500 MB | 2–4 GB |
| Android 模擬器管理 | ❌ 沒有 | ✅ 有 |
| Gradle 問題排查 | ❌ 弱 | ✅ 強 |

**兩個都裝，主力用 VS Code。** Android Studio 只在兩種時候開：
建立／管理模擬器，以及 Gradle 建置出錯要看詳細堆疊時。

Apple Silicon 記得下載 **Apple Silicon 版**的 VS Code
（官網會自動偵測，但手動下載時別選成 Intel 版，會透過 Rosetta 跑、明顯變慢）：

```bash
brew install --cask visual-studio-code    # Homebrew 會自動選對架構
```

### 必裝擴充

專案已附 `.vscode/extensions.json`，開啟資料夾時 VS Code 會跳出建議安裝的提示，
按「Install All」即可。清單：

| 擴充 | 用途 |
|---|---|
| **Flutter** | 語法、補全、hot reload、DevTools（會自動附帶 Dart） |
| **Claude Code** | 在編輯器裡直接對話與改碼 |
| **Error Lens** | 把錯誤訊息顯示在該行行尾，不用移到底部看 Problems |
| **Better Comments** | 讓 `// ⚠` `// TODO` 這類註解有顏色 |

⚠️ **不要**裝 Awesome Flutter Snippets、Flutter Widget Snippets 這類 snippet 套件。
它們產生的程式碼風格與本專案的 lint 規則衝突，你會一直在修 `dart fix` 的東西。

### 專案已附的設定

| 檔案 | 作用 |
|---|---|
| `.vscode/settings.json` | 存檔自動 format + 自動 hot reload + 自動整理 import |
| `.vscode/launch.json` | 四個啟動設定：Chrome / 行動裝置 / Profile / 真實後端 |
| `.vscode/tasks.json` | `Cmd+Shift+B` 直接跑 harness |
| `.vscode/extensions.json` | 開專案時提示安裝上面四個擴充 |

`flutterHotReloadOnSave: always` 意思是**按 `Cmd+S` 就等於 hot reload**，
不需要切到終端機按 `r`。這是 Flutter 開發最重要的一個設定。

### Claude Code 安裝

```bash
npm install -g @anthropic-ai/claude-code
cd joformosa
claude
```

VS Code 內則裝 Claude Code 擴充，用 `Cmd+Esc` 開啟側邊面板。
兩者共用同一份設定與同一個 session。

### 這個專案為 Claude Code 準備了什麼

`.claude/` 資料夾不是裝飾，它是整套 AI 工作流的實作：

```
.claude/
├─ agents/
│   ├─ architect.md    只能寫 spec 與 domain 介面，不能寫 UI
│   ├─ designer.md     只能寫 Design Token 與元件規格
│   ├─ engineer.md     只能寫 data/presentation/test
│   └─ reviewer.md     只能讀，且看不到 engineer 的推理過程
├─ commands/
│   ├─ build.md        /build T-042 → 依 spec 實作並自動迴圈到 harness 全綠
│   └─ review.md       /review T-042 → 以獨立 context 審查
└─ settings.json       hooks
```

`settings.json` 裡有兩個 hook，這是最實際的部分：

- **PostToolUse** — Claude 每次改完 `.dart` 檔，自動跑 `dart format` + `flutter analyze`。
  它馬上看到自己造成的錯誤，不會等到你發現。
- **Stop** — Claude 說「我做完了」的當下，自動跑 `bash tool/harness.sh --fast`。
  **它不能自己宣稱完成**，exit code 才算數。

專案根目錄的 `CLAUDE.md` 是專案憲法，Claude Code 每次啟動都會讀。
分層鐵律、錯誤處理規則、完成的定義都在裡面。

### 實際的工作流

終端機開兩個分頁：

```bash
# 分頁 1：跑著 App，改完存檔就自動 reload
flutter run -d chrome

# 分頁 2：Claude Code
claude
```

在 Claude Code 裡：

```
/build T-060          依 spec 實作團長端，自動迴圈到 harness 全綠
/review T-060         以獨立 context 審查剛才的實作
```

想手動確認品質：VS Code 按 `Cmd+Shift+B`，或終端機 `bash tool/harness.sh`。

### 常用快捷鍵

| 快捷鍵 | 動作 |
|---|---|
| `Cmd+S` | 存檔 → 自動 format → 自動 hot reload |
| `Cmd+.` | Quick Fix（把 widget 包起來、加 const、加 import） |
| `Cmd+Shift+P` → `Flutter: Select Device` | 換裝置 |
| `Cmd+Shift+P` → `Dart: Open DevTools` | 開效能／Widget Inspector |
| `Cmd+Shift+B` | 跑 harness |
| `Cmd+Esc` | 開 Claude Code 面板 |
| `F5` | 啟動 debug（用 launch.json 的設定） |

`Cmd+.` 是 Flutter 開發用最多的一個。游標放在 widget 上按它，
可以直接「Wrap with Padding / Column / Builder」，比手打快非常多。
