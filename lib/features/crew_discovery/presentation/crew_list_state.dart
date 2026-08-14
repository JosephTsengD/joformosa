import '../../../core/utils/failure.dart';
import '../domain/entities.dart';

/// 五態而非 AsyncValue 的三態。
///
/// 理由（計劃書 5.3）：offline-first 場景下「有快取但正在刷新」和「首次載入」
/// 的 UI 完全不同——前者不該顯示骨架屏，否則使用者每次回到列表都會看到閃爍。
/// 用 sealed class 顯式建模，讓編譯器在新增狀態時強迫處理所有 UI 分支。
sealed class CrewListState {
  const CrewListState();
}

final class CrewListInitial extends CrewListState {
  const CrewListInitial();
}

final class CrewListLoading extends CrewListState {
  const CrewListLoading();
}

final class CrewListRefreshing extends CrewListState {
  const CrewListRefreshing(this.cached);
  final List<Crew> cached;
}

final class CrewListData extends CrewListState {
  const CrewListData({
    required this.crews,
    required this.isStale,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  final List<Crew> crews;
  final bool isStale;
  final bool hasMore;
  final bool isLoadingMore;

  CrewListData copyWith({
    List<Crew>? crews,
    bool? isStale,
    bool? hasMore,
    bool? isLoadingMore,
  }) =>
      CrewListData(
        crews: crews ?? this.crews,
        isStale: isStale ?? this.isStale,
        hasMore: hasMore ?? this.hasMore,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );
}

final class CrewListEmpty extends CrewListState {
  const CrewListEmpty(this.appliedFilter);
  final CrewFilter appliedFilter;
}

final class CrewListError extends CrewListState {
  const CrewListError(this.failure, {this.cached});
  final AppFailure failure;
  final List<Crew>? cached;
}
