import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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
  SupabaseAuthRepository(this._auth);

  final sb.GoTrueClient _auth;

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

  Future<Result<AppUser>> _lineFlow() async {
    // 需要 flutter_web_auth_2 開啟系統瀏覽器走 authorize，
    // 拿到 code 後 POST 給 line-auth Edge Function 換 Supabase session。
    // 尚未接上時明確回報，不要靜默失敗。
    return const Err<AppUser>(
      AuthFailure(reason: 'line_not_configured'),
    );
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
