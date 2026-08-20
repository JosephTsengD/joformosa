import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LINE Login v2.1（OAuth 2.0 + OpenID Connect）的客戶端部分。
///
/// 為什麼 token 交換不在這裡做
/// ─────────────────────────────────────────────────────────
/// LINE 的 token endpoint 需要 `channel_secret`。**任何進到前端的密鑰
/// 都是公開的**——web 打開 DevTools 就看得到，App 反編譯也拿得到。
/// 所以這個類別只負責「把使用者送去 LINE」與「驗證回來的東西」，
/// 換 token 由 Edge Function 執行（見 supabase/functions/line-auth）。
///
///   App                      Edge Function            LINE
///    │  ① 整頁跳轉 authorize   │                        │
///    ├────────────────────────────────────────────────▶│
///    │  ② 導回 callback 帶 code│                        │
///    │◀────────────────────────────────────────────────┤
///    │  ③ POST {code,verifier} │                        │
///    ├────────────────────────▶│  ④ code + secret       │
///    │                         ├───────────────────────▶│
///    │  ⑦ Supabase session     │  ⑤ id_token → ⑥ 驗簽    │
///    │◀────────────────────────┤◀───────────────────────┤
class LineAuthService {
  LineAuthService({
    required this.channelId,
    required this.redirectUri,
    required SharedPreferences prefs,
    Random? random,
  })  : _prefs = prefs,
        _random = random ?? Random.secure();

  final String channelId;

  /// 必須與 LINE Developers Console 註冊的 Callback URL **完全一致**，
  /// 包含結尾斜線。不一致時 LINE 直接回錯誤，且訊息不會告訴你差在哪。
  final String redirectUri;

  final SharedPreferences _prefs;
  final Random _random;

  static const _authorizeUrl = 'https://access.line.me/oauth2/v2.1/authorize';
  static const _pendingKey = 'line.pending.v1';

  /// 建立授權請求，並把 verifier / state / nonce 存起來。
  ///
  /// **一定要存。** web 是整頁跳轉，記憶體中的變數在導向 LINE 的那一刻
  /// 就全部消失了，回來時是一個全新的 App 實例。
  Future<LineAuthRequest> start() async {
    final verifier = _randomString(64);
    final state = _randomString(32);
    final nonce = _randomString(32);

    final url = Uri.parse(_authorizeUrl).replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': channelId,
        'redirect_uri': redirectUri,
        'state': state,
        // openid + profile 不需要事前申請；email 才需要送審。
        'scope': 'openid profile',
        'nonce': nonce,
        'code_challenge': challengeFor(verifier),
        'code_challenge_method': 'S256',
        'bot_prompt': 'normal',
      },
    );

    final request = LineAuthRequest(
      authorizeUrl: url.toString(),
      codeVerifier: verifier,
      state: state,
      nonce: nonce,
    );

    await _prefs.setString(
      _pendingKey,
      jsonEncode(<String, String>{
        'verifier': verifier,
        'state': state,
        'nonce': nonce,
      }),
    );
    return request;
  }

  /// PKCE 的 code_challenge：base64url(sha256(verifier))，**去掉結尾的 =**。
  ///
  /// RFC 7636 明確要求無 padding。留著 `=` 的話 LINE 會回
  /// `invalid_grant`，而錯誤訊息不會提到 padding——這個坑很花時間。
  static String challengeFor(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// 驗證 LINE 導回的網址。
  ///
  /// 回傳 sealed 型別而非拋例外：呼叫端必須處理每一種失敗，
  /// 而「使用者按了取消」跟「state 不符（可能是攻擊）」需要完全不同的反應。
  Future<LineCallbackResult> complete(Uri callback) async {
    final raw = _prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) {
      // 沒有待處理的流程卻收到 callback：可能是使用者直接貼網址，
      // 也可能是有人試圖注入一個 code。兩種都不該繼續。
      return const LineCallbackError(LineCallbackFailure.noPendingRequest);
    }

    final pending = jsonDecode(raw) as Map<String, dynamic>;
    final params = callback.queryParameters;

    if (params['error'] != null) {
      await clearPending();
      return LineCallbackError(
        params['error'] == 'access_denied'
            ? LineCallbackFailure.userCancelled
            : LineCallbackFailure.providerError,
      );
    }

    // state 比對是 CSRF 的唯一防線。不比對的話，攻擊者可以誘導你的
    // 瀏覽器帶著**他的** code 回來，結果你登入了他的帳號。
    if (params['state'] != pending['state']) {
      await clearPending();
      return const LineCallbackError(LineCallbackFailure.stateMismatch);
    }

    final code = params['code'];
    if (code == null || code.isEmpty) {
      await clearPending();
      return const LineCallbackError(LineCallbackFailure.missingCode);
    }

    await clearPending();
    return LineCallbackOk(
      code: code,
      codeVerifier: pending['verifier'] as String,
      nonce: pending['nonce'] as String,
    );
  }

  Future<void> clearPending() async => _prefs.remove(_pendingKey);

  bool get hasPendingRequest => (_prefs.getString(_pendingKey) ?? '').isNotEmpty;

  String _randomString(int length) {
    // RFC 7636 的 unreserved 字元集
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List<String>.generate(
      length,
      (_) => chars[_random.nextInt(chars.length)],
    ).join();
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

enum LineCallbackFailure {
  noPendingRequest,
  userCancelled,
  providerError,
  stateMismatch,
  missingCode,
}

sealed class LineCallbackResult {
  const LineCallbackResult();
}

final class LineCallbackOk extends LineCallbackResult {
  const LineCallbackOk({
    required this.code,
    required this.codeVerifier,
    required this.nonce,
  });

  final String code;
  final String codeVerifier;
  final String nonce;
}

final class LineCallbackError extends LineCallbackResult {
  const LineCallbackError(this.reason);
  final LineCallbackFailure reason;
}
