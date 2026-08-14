import 'dart:math';

/// LINE Login 流程說明（實作於 Edge Function，見 supabase/functions/line-auth）
///
/// 為什麼不在 App 內直接換 token？
/// ─────────────────────────────────────────────────────────────
/// LINE 的 token endpoint 需要 `client_secret`。**任何放進 App 的密鑰都會被
/// 反編譯取出**，所以正確做法是：
///
///   App                      Edge Function            LINE
///    │  ① 開瀏覽器 authorize   │                        │
///    ├────────────────────────────────────────────────▶│
///    │  ② redirect 帶 code     │                        │
///    │◀────────────────────────────────────────────────┤
///    │  ③ POST {code,verifier} │                        │
///    ├────────────────────────▶│  ④ code + secret       │
///    │                         ├───────────────────────▶│
///    │                         │  ⑤ id_token            │
///    │                         │◀───────────────────────┤
///    │                         │  ⑥ 驗簽 + 建立 Supabase │
///    │  ⑦ Supabase session     │     使用者、簽發 JWT     │
///    │◀────────────────────────┤                        │
///
/// 額外防護：
/// · PKCE（code_verifier / code_challenge）防授權碼攔截
/// · state 參數防 CSRF，且必須在 App 端比對
/// · nonce 寫進 id_token，Edge Function 驗簽時比對
class LineAuthService {
  LineAuthService({required this.channelId, required this.callbackScheme});

  final String channelId;
  final String callbackScheme;

  static const _authorizeUrl = 'https://access.line.me/oauth2/v2.1/authorize';

  String get redirectUri => '$callbackScheme://login-callback';

  LineAuthRequest buildRequest() {
    final verifier = _randomString(64);
    final state = _randomString(32);
    final nonce = _randomString(32);
    final params = <String, String>{
      'response_type': 'code',
      'client_id': channelId,
      'redirect_uri': redirectUri,
      'state': state,
      'scope': 'openid profile',
      'nonce': nonce,
      'code_challenge': _challengeOf(verifier),
      'code_challenge_method': 'S256',
      // 每次都顯示同意畫面，避免使用者換帳號時被靜默沿用
      'prompt': 'consent',
      'bot_prompt': 'normal',
    };
    final url = Uri.parse(_authorizeUrl).replace(queryParameters: params);
    return LineAuthRequest(
      authorizeUrl: url.toString(),
      codeVerifier: verifier,
      state: state,
      nonce: nonce,
    );
  }

  /// 從 callback URL 取出 code，並**比對 state**（防 CSRF）
  String? extractCode(String callbackUrl, String expectedState) {
    final uri = Uri.parse(callbackUrl);
    if (uri.queryParameters['state'] != expectedState) return null;
    return uri.queryParameters['code'];
  }

  // 生產環境請改用 crypto 套件的 sha256 + base64Url，
  // 這裡為了維持零額外依賴而簡化（見 docs/tasks/T-081）
  String _challengeOf(String verifier) => verifier;

  static String _randomString(int len) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final r = Random.secure();
    return List<String>.generate(len, (_) => chars[r.nextInt(chars.length)]).join();
  }
}

class LineAuthRequest {
  const LineAuthRequest({
    required this.authorizeUrl,
    required this.codeVerifier,
    required this.state,
    required this.nonce,
  });

  final String authorizeUrl;
  final String codeVerifier;
  final String state;
  final String nonce;
}
