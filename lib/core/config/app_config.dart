/// 執行期設定，全部來自 `--dart-define`。
///
/// 為什麼不用 .env 檔？
/// ─────────────────────────────────────────────────────────
/// Flutter web 會把 assets 一起打包出去，.env 放進 assets 等於公開。
/// dart-define 在編譯期就內嵌成常數，行為明確、不會誤把檔案帶上線。
///
/// 這裡面的值**都是可以公開的**（anon key 本來就是公開的，
/// 真正的安全邊界是 RLS，見 supabase/migrations/0002_rls.sql）。
/// 任何不可公開的密鑰只能存在於 Edge Function 的環境變數。
abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Supabase 正在把 `anon key` 換成 `publishable key`（sb_publishable_...），
  /// 舊金鑰預計 2026 年底停用。
  ///
  /// 兩個環境變數都接受，優先用新的——這樣既有的 GitHub Secrets
  /// 不必立刻改名，遷移可以分兩步走。
  static const _publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const _legacyAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get supabaseKey =>
      _publishableKey.isNotEmpty ? _publishableKey : _legacyAnonKey;

  static const lineChannelId = String.fromEnvironment('LINE_CHANNEL_ID');
  static const lineCallbackScheme =
      String.fromEnvironment('LINE_CALLBACK_SCHEME', defaultValue: 'joincrew');

  /// 強制使用本地合成資料（開發、離線、或後端還沒架好時）
  static const forceFakeBackend =
      bool.fromEnvironment('USE_FAKE_BACKEND', defaultValue: false);

  /// 設定齊全才連真實後端。缺任何一項就退回合成資料，
  /// 這讓 `flutter run` 在沒有任何設定時仍然可用。
  static bool get hasSupabase =>
      !forceFakeBackend && supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty;

  static bool get hasLineLogin => hasSupabase && lineChannelId.isNotEmpty;
}
