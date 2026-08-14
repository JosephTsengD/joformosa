import 'failure.dart';

/// Dart 3 sealed class 取代 `Either<L, R>`。
/// 好處：switch 窮盡性由編譯器保證，且無外部依賴。
sealed class Result<T> {
  const Result();

  R fold<R>({
    required R Function(T value) ok,
    required R Function(AppFailure failure) err,
  }) =>
      switch (this) {
        Ok<T>(:final value) => ok(value),
        Err<T>(:final failure) => err(failure),
      };

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  bool get isOk => this is Ok<T>;
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}
