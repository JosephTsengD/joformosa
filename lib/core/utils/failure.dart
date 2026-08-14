/// 統一失敗型別。
///
/// 規則：data 層負責把所有原始例外（PostgrestException / SocketException /
/// FormatException）轉譯成 AppFailure。domain 與 presentation **永遠不 catch
/// 原始例外**，這讓錯誤處理可測試、可窮盡、可 i18n。
sealed class AppFailure {
  const AppFailure();

  /// i18n key，不是寫死的中文
  String get messageKey;
  bool get isRetryable;
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure();
  @override
  String get messageKey => 'error.network';
  @override
  bool get isRetryable => true;
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
  @override
  String get messageKey => 'error.timeout';
  @override
  bool get isRetryable => true;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure(this.resource);
  final String resource;
  @override
  String get messageKey => 'error.notFound';
  @override
  bool get isRetryable => false;
}

final class AuthFailure extends AppFailure {
  const AuthFailure({this.reason = ''});
  final String reason;
  @override
  String get messageKey => 'error.auth';
  @override
  bool get isRetryable => false;
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(this.fieldErrors);
  final Map<String, String> fieldErrors;
  @override
  String get messageKey => 'error.validation';
  @override
  bool get isRetryable => false;
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure(this.retryAfter);
  final Duration retryAfter;
  @override
  String get messageKey => 'error.rateLimit';
  @override
  bool get isRetryable => true;
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure(this.detail);
  final String detail;
  @override
  String get messageKey => 'error.unknown';
  @override
  bool get isRetryable => true;
}
