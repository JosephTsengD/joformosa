import '../../../core/utils/result.dart';
import 'auth_models.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;

  /// 匿名登入：先讓使用者能用（收藏存本地），日後可升級綁定 LINE
  Future<Result<AppUser>> signInAnonymously();

  /// LINE Login v2.1（OAuth 2.0 + OIDC）
  Future<Result<AppUser>> signInWithLine();

  /// 匿名 → LINE 的帳號升級。**必須保留既有收藏**（F-07 驗收條件）
  Future<Result<AppUser>> linkLine();

  Future<Result<void>> signOut();
}
