import 'dart:async';

import '../../../core/utils/id_gen.dart';
import '../../../core/utils/result.dart';
import '../domain/auth_models.dart';
import '../domain/auth_repository.dart';

/// 開發用實作：模擬 LINE 登入的完整時序，但不打真實 API。
/// 真實實作見 supabase/functions/line-auth 與 README。
class FakeAuthRepository implements AuthRepository {
  final _controller = StreamController<AppUser?>.broadcast();
  final _ids = IdGen();
  AppUser? _user;

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  void _emit(AppUser? u) {
    _user = u;
    _controller.add(u);
  }

  @override
  Future<Result<AppUser>> signInAnonymously() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final u = AppUser(
      id: _ids.next('anon'),
      provider: AuthProvider.guest,
    );
    _emit(u);
    return Ok<AppUser>(u);
  }

  @override
  Future<Result<AppUser>> signInWithLine() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    const u = AppUser(
      id: 'line-user-001',
      provider: AuthProvider.line,
      displayName: '陳大明',
      lineUserId: 'U4af4980629...',
    );
    _emit(u);
    // 這裡可以用 const，因為上面是 `const u = AppUser(...)`——
    // u 本身就是編譯期常數。
    //
    // 但下面 linkLine() 的 `return Ok<AppUser>(u)` **不能**加 const，
    // 那裡的 u 是 `final u = AppUser(id: prev?.id ?? ...)`，值要到執行期才知道。
    // 同樣一行程式碼能不能加 const，取決於變數是怎麼宣告的。
    return const Ok<AppUser>(u);
  }

  /// 匿名 → LINE 升級：id 沿用，確保本地收藏不遺失（F-07）
  @override
  Future<Result<AppUser>> linkLine() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final prev = _user;
    final u = AppUser(
      id: prev?.id ?? 'line-user-001',
      provider: AuthProvider.line,
      displayName: '陳大明',
      lineUserId: 'U4af4980629...',
    );
    _emit(u);
    return Ok<AppUser>(u);
  }

  @override
  Future<Result<void>> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _emit(null);
    return const Ok<void>(null);
  }
}
