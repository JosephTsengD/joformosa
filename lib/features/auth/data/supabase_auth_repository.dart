import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'line_auth_service.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/result.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// 真實 Supabase Auth。
///
/// 匿名登入的用途：使用者不必先註冊就能收藏、送出社團。
/// RLS 的 `auth.uid()` 對匿名使用者一樣有效，所以授權完全不受影響。
///
/// ⚠ 需要在 Supabase Dashboard → Authentication → Providers
///   啟用 **Anonymous sign-ins**，否則會回 422。
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth, {LineAuthService? line, sb.SupabaseClient? client})
      : _line = line,
        _client = client;

  final sb.GoTrueClient _auth;
  final LineAuthService? _line;
  final sb.SupabaseClient? _client;

  AppUser? _map(sb.User? u) {
    if (u == null) return null;
    final meta = u.userMetadata ?? <String, dynamic>{};
    final isLine = meta['provider'] == 'line';
    return AppUser(
      id: u.id,
      provider: isLine ? AuthProvider.line : AuthProvider.guest,
      displayName: meta['display_name'] as String?,
      avatarUrl: meta['avatar_url'] as String?,
      lineUserId: meta['line_user_id'] as String?,
    );
  }

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* _auth.onAuthStateChange.map((sb.AuthState s) => _map(s.session?.user));
  }

  @override
  Future<Result<AppUser>> signInAnonymously() async {
    try {
      final res = await _auth.signInAnonymously();
      final user = _map(res.user);
      if (user == null) {
        return const Err<AppUser>(AuthFailure(reason: 'no user returned'));
      }
      return Ok<AppUser>(user);
    } on sb.AuthException catch (e) {
      // 最常見的原因是 Dashboard 沒開啟 Anonymous sign-ins
      return Err<AppUser>(AuthFailure(reason: e.message));
    } on Object catch (e) {
      return Err<AppUser>(_network(e));
    }
  }

  /// LINE Login 需要 Edge Function 交換 token（channel secret 不可進 App）。
  /// 完整流程見 docs/adr/007-line-login.md 與 supabase/functions/line-auth。
  @override
  Future<Result<AppUser>> signInWithLine() => _lineFlow();

  /// 匿名 → LINE 升級。用 link 而非重新登入，確保 user id 不變，
  /// 既有的收藏與送出紀錄才不會遺失（F-07 驗收條件）。
  @override
  Future<Result<AppUser>> linkLine() => _lineFlow();

  /// 啟動 LINE 登入：整頁跳轉到 LINE 授權頁。
  ///
  /// 這個 Future **不會**回傳成功——瀏覽器會離開這一頁。
  /// 真正的結果在 callback 路由由 `completeLineSignIn` 處理。
  /// 把這件事寫進型別會讓 AuthRepository 介面變複雜，所以用註解說明，
  /// 並讓呼叫端不要等待它。
  Future<Result<AppUser>> _lineFlow() async {
    final line = _line;
    if (line == null) {
      return const Err<AppUser>(AuthFailure(reason: 'line_not_configured'));
    }
    try {
      final request = await line.start();
      await launchUrl(
        Uri.parse(request.authorizeUrl),
        // web：同分頁跳轉。開新分頁的話 callback 回不到原本的 App 狀態。
        webOnlyWindowName: '_self',
        mode: LaunchMode.platformDefault,
      );
      return const Err<AppUser>(AuthFailure(reason: 'line_redirecting'));
    } on Object catch (e) {
      return Err<AppUser>(_network(e));
    }
  }

  /// 處理 LINE 導回的 callback。由 `/auth/line` 路由透過 domain 介面呼叫。
  @override
  Future<Result<AppUser>> completeExternalSignIn(Uri callback) async {
    final line = _line;
    final client = _client;
    if (line == null || client == null) {
      return const Err<AppUser>(AuthFailure(reason: 'line_not_configured'));
    }

    final result = await line.complete(callback);
    switch (result) {
      case LineCallbackError(:final reason):
        return Err<AppUser>(AuthFailure(reason: reason.name));

      case LineCallbackOk(:final code, :final codeVerifier, :final nonce):
        try {
          // channel secret 在 Edge Function 裡，這裡只送 code 與 verifier
          final response = await client.functions.invoke(
            'line-auth',
            body: <String, dynamic>{
              'code': code,
              'codeVerifier': codeVerifier,
              'redirectUri': line.redirectUri,
              'nonce': nonce,
            },
          );

          final data = response.data;
          if (data is! Map || data['tokenHash'] == null) {
            return const Err<AppUser>(AuthFailure(reason: 'exchange_failed'));
          }

          await _auth.verifyOTP(
            type: sb.OtpType.magiclink,
            tokenHash: data['tokenHash'] as String,
          );

          final user = currentUser;
          if (user == null) {
            return const Err<AppUser>(AuthFailure(reason: 'no_session'));
          }
          return Ok<AppUser>(user);
        } on Object catch (e) {
          return Err<AppUser>(_network(e));
        }
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return const Ok<void>(null);
    } on Object catch (e) {
      return Err<void>(_network(e));
    }
  }

  AppFailure _network(Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('socket') ||
        t.contains('connection') ||
        t.contains('failed host lookup')) {
      return const NetworkFailure();
    }
    return UnknownFailure(e.toString());
  }
}
