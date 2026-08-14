import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../domain/crew_repository.dart';
import '../domain/entities.dart';
import 'crew_list_state.dart';

class CrewListController extends StateNotifier<CrewListState> {
  CrewListController(this._repo) : super(const CrewListLoading()) {
    _load(_filter, reset: true);
  }

  final CrewRepository _repo;

  CrewFilter _filter = const CrewFilter();
  CrewFilter get filter => _filter;

  Timer? _debounce;
  int _requestSeq = 0; // 競態防護：只有最新一次的結果會被套用（F-02）
  Cursor? _cursor;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  /// 300ms debounce：快速連點多個 chip 只發 1 次請求
  void applyFilter(CrewFilter next) {
    _filter = next;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _load(next, reset: true);
    });
  }

  void clearFilter() => applyFilter(const CrewFilter());

  Future<void> refresh() async {
    final current = state;
    if (current is CrewListData) {
      state = CrewListRefreshing(current.crews);
    }
    await _load(_filter, reset: true);
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! CrewListData) return;
    if (!current.hasMore || current.isLoadingMore) return; // 防重複觸發
    state = current.copyWith(isLoadingMore: true);
    await _load(_filter, reset: false);
  }

  Future<void> _load(CrewFilter f, {required bool reset}) async {
    final seq = ++_requestSeq;
    if (reset) _cursor = null;

    final existing = switch (state) {
      CrewListData(:final crews) => crews,
      CrewListRefreshing(:final cached) => cached,
      _ => const <Crew>[],
    };

    if (reset && existing.isEmpty) state = const CrewListLoading();

    await for (final result in _repo.watchCrews(f, after: reset ? null : _cursor)) {
      if (seq != _requestSeq) return; // 舊請求的結果直接丟棄

      switch (result) {
        case Ok<CrewPage>(:final value):
          final merged = reset
              ? value.items
              : <Crew>[
                  ...existing,
                  // 去重：分頁合併時 id 必須唯一（8.4 不變式）
                  ...value.items.where((c) => !existing.any((e) => e.id == c.id)),
                ];
          _cursor = value.nextCursor;
          state = merged.isEmpty
              ? CrewListEmpty(f)
              : CrewListData(crews: merged, isStale: false, hasMore: value.hasMore);

        case Err<CrewPage>(:final failure):
          // 有快取則降級顯示，不整頁報錯
          state = CrewListError(failure, cached: existing.isEmpty ? null : existing);
      }
    }
  }
}
