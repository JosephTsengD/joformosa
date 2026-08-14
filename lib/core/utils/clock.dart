/// 全專案禁止直接呼叫 `DateTime.now()`。
/// 一律注入 Clock，否則第 8.3 節的時間邊界案例無法測試。
abstract interface class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime now() => DateTime.now();
}

/// 測試用：可任意設定與推進的時鐘。
class FakeClock implements Clock {
  FakeClock(this._now);
  DateTime _now;
  @override
  DateTime now() => _now;
  void set(DateTime t) => _now = t;
  void advance(Duration d) => _now = _now.add(d);
}
