import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/primitives.dart';
import '../domain/entities.dart';
import 'crew_card.dart';
import 'crew_list_controller.dart';
import 'crew_list_state.dart';
import 'filter_sheet.dart';
import 'search_field.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key, this.initialFilter});

  /// 從網址還原的初始篩選（含搜尋關鍵字）。
  /// null 代表使用者是從 App 內導覽進來的，沿用 controller 現有狀態。
  final CrewFilter? initialFilter;

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final ScrollController _scroll = ScrollController();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);

    final initial = widget.initialFilter;
    if (initial != null && !initial.isEmpty) {
      // 在第一幀之後套用：initState 期間不能改動其他 provider 的狀態
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(crewListProvider.notifier).applyFilter(initial);
      });
    }
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// 剩 3 張時就預先載入下一頁，不要等使用者捲到底（F-03）
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final remaining = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (remaining < 420) {
      unawaited(ref.read(crewListProvider.notifier).loadMore());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final state = ref.watch(crewListProvider);
    final ctrl = ref.read(crewListProvider.notifier);
    final now = ref.watch(clockProvider).now();
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      body: RefreshIndicator(
        color: c.accentPrimary,
        onRefresh: ctrl.refresh,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            _appBar(c, s),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeaderDelegate(
                child: _FilterBar(
                  filter: ctrl.filter,
                  strings: s,
                  onSportChanged: (Sport? sport) => _apply(
                    sport == null
                        ? ctrl.filter.copyWith(clearSport: true)
                        : ctrl.filter.copyWith(sport: sport),
                  ),
                  onOpenSheet: () => _openFilterSheet(context, s),
                  onQueryChanged: _onQueryChanged,
                  onQuerySubmitted: _onQuerySubmitted,
                  onSearchFocusChanged: (bool f) => setState(() => _searchFocused = f),
                  onTimeWindowToggled: (TimeWindow w) =>
                      _apply(ctrl.filter.copyWith(timeWindow: w)),
                ),
              ),
            ),
            if (_searchFocused && ctrl.filter.query.isEmpty)
              SliverToBoxAdapter(
                child: RecentSearchPanel(
                  entries: ref.watch(recentSearchProvider),
                  strings: s,
                  onPick: (String q) {
                    _onQueryChanged(q);
                    _onQuerySubmitted(q);
                    FocusScope.of(context).unfocus();
                  },
                  onRemove: (String q) =>
                      ref.read(recentSearchProvider.notifier).remove(q),
                  onClearAll: () => ref.read(recentSearchProvider.notifier).clear(),
                ),
              ),
            if (ref.watch(backendDegradedProvider))
              SliverToBoxAdapter(
                child: StaleBanner(
                  text: s.degradedBanner,
                  actionLabel: s.refreshNow,
                  onRefresh: ctrl.refresh,
                ),
              ),
            if (ref.watch(demoBannerVisibleProvider))
              SliverToBoxAdapter(
                child: DemoBanner(
                  badge: s.demoBadge,
                  body: s.demoBannerBody,
                  dismissLabel: s.demoDismiss,
                  onDismiss: () => ref.read(demoBannerVisibleProvider.notifier).dismiss(),
                ),
              ),
            ..._body(state, now, s, favorites, ctrl),
            const SliverToBoxAdapter(child: SizedBox(height: Space.xxxl)),
          ],
        ),
      ),
    );
  }

  Widget _appBar(AppColors c, Strings s) {
    final now = ref.watch(clockProvider).now();
    final state = ref.watch(crewListProvider);
    final todayCount = state is CrewListData
        ? state.crews.where((Crew crew) {
            final n = crew.nextSession;
            return n != null &&
                n.startsAt.year == now.year &&
                n.startsAt.month == now.month &&
                n.startsAt.day == now.day;
          }).length
        : 0;

    return SliverAppBar(
      pinned: false,
      floating: true,
      backgroundColor: c.surface,
      elevation: 0,
      toolbarHeight: 76,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(s.appName, style: AppText.display.copyWith(color: c.textPrimary)),
          const SizedBox(height: 2),
          Text(
            todayCount > 0
                ? (s.locale.startsWith('zh')
                    ? '今天有 $todayCount 場團練'
                    : '$todayCount sessions today')
                : s.tagline,
            style: AppText.caption.copyWith(
              color: todayCount > 0 ? c.accentPrimary : c.textSecondary,
            ),
          ),
        ],
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.favorite_border_rounded),
          tooltip: s.navFavorites,
          onPressed: () => context.go('/favorites'),
        ),
        IconButton(
          icon: const Icon(Icons.person_outline_rounded),
          tooltip: s.navMe,
          onPressed: () => context.go('/me'),
        ),
        const SizedBox(width: Space.sm),
      ],
    );
  }

  List<Widget> _body(
    CrewListState state,
    DateTime now,
    Strings s,
    Set<String> favorites,
    CrewListController ctrl,
  ) {
    // 五態窮盡：編譯器保證新增狀態時不會漏掉 UI 分支
    return switch (state) {
      CrewListInitial() => <Widget>[const SliverToBoxAdapter(child: SizedBox.shrink())],
      CrewListLoading() => <Widget>[_skeletonList()],
      CrewListRefreshing(:final cached) =>
        _grid(cached, now, s, favorites, showTopProgress: true),
      CrewListData(:final crews, :final isStale, :final hasMore, :final isLoadingMore) =>
        <Widget>[
          if (isStale) _staleBanner(s, ctrl),
          ..._grid(crews, now, s, favorites),
          if (isLoadingMore) _footerSpinner(),
          if (!hasMore && crews.isNotEmpty) _footerText(s.allLoaded),
        ],
      CrewListEmpty(:final appliedFilter) => <Widget>[
          SliverFillRemaining(
            hasScrollBody: false,
            child: appliedFilter.query.isNotEmpty
                // 搜尋落空時要說出「找不到什麼」。
                // 通用文案會讓使用者以為是網站壞了，而不是關鍵字沒中。
                ? EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: s.searchEmptyTitle(appliedFilter.query),
                    hint: s.searchEmptyHint,
                    actionLabel: s.searchClear,
                    onAction: () => _onQueryChanged(''),
                  )
                : EmptyStateView(
                    icon: Icons.search_off_rounded,
                    title: s.emptyNoResult,
                    hint: s.emptyNoResultHint,
                    actionLabel: appliedFilter.isEmpty ? null : s.filterClear,
                    onAction: appliedFilter.isEmpty ? null : ctrl.clearFilter,
                  ),
          ),
        ],
      CrewListError(:final failure, :final cached) => cached != null
          // 降級：有舊資料仍可用，只在頂部顯示錯誤條
          ? <Widget>[_staleBanner(s, ctrl), ..._grid(cached, now, s, favorites)]
          : <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.wifi_off_rounded,
                  title: s.errorOf(failure.messageKey),
                  hint: s.disclaimer,
                  actionLabel: failure.isRetryable ? s.retry : null,
                  onAction: failure.isRetryable ? ctrl.refresh : null,
                ),
              ),
            ],
    };
  }

  Widget _skeletonList() => SliverPadding(
        padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
        sliver: SliverList.builder(
          itemCount: 5,
          itemBuilder: (BuildContext _, int __) => const SkeletonCard(),
        ),
      );

  List<Widget> _grid(
    List<Crew> crews,
    DateTime now,
    Strings s,
    Set<String> favorites, {
    bool showTopProgress = false,
  }) =>
      <Widget>[
        if (showTopProgress)
          SliverToBoxAdapter(
            child: LinearProgressIndicator(
              minHeight: 2,
              color: context.colors.accentPrimary,
              backgroundColor: Colors.transparent,
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.md, Space.lg, 0),
          sliver: SliverList.separated(
            itemCount: crews.length,
            separatorBuilder: (BuildContext _, int __) =>
                const SizedBox(height: Space.md),
            itemBuilder: (BuildContext context, int i) {
              final crew = crews[i];
              return RepaintBoundary(
                child: CrewCard(
                  crew: crew,
                  now: now,
                  strings: s,
                  isFavorite: favorites.contains(crew.id),
                  onTap: () => context.go('/crews/${crew.slug}'),
                  onToggleFavorite: () => _toggleFavorite(crew, s),
                ),
              );
            },
          ),
        ),
      ];

  Widget _staleBanner(Strings s, CrewListController ctrl) => SliverToBoxAdapter(
        child: StaleBanner(
          text: s.offline,
          actionLabel: s.refreshNow,
          onRefresh: ctrl.refresh,
        ),
      );

  Widget _footerSpinner() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: context.colors.accentPrimary,
              ),
            ),
          ),
        ),
      );

  Widget _footerText(String text) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xxl),
          child: Center(
            child: Text(
              text,
              style: AppText.micro.copyWith(color: context.colors.textTertiary),
            ),
          ),
        ),
      );

  /// 套用篩選並把狀態寫進網址，讓使用者可以分享／收藏搜尋結果。
  void _apply(CrewFilter next) {
    ref.read(crewListProvider.notifier).applyFilter(next);
    // replace 而非 push：篩選不該在返回鍵堆疊裡累積成幾十層
    context.replace(next.toLocation());
  }

  void _onQueryChanged(String query) {
    _apply(ref.read(crewListProvider.notifier).filter.copyWith(query: query));
  }

  /// 送出才記錄，不是每次輸入都記——否則「夜」「夜跑」「夜跑團」會存成三筆
  void _onQuerySubmitted(String query) {
    if (query.trim().isEmpty) return;
    ref.read(recentSearchProvider.notifier).record(query);
  }

  Future<void> _toggleFavorite(Crew crew, Strings s) async {
    final added = await ref.read(favoritesProvider.notifier).toggle(crew.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1400),
          content: Text(added ? '${s.saved}：${crew.name}' : s.save),
        ),
      );
  }

  Future<void> _openFilterSheet(BuildContext context, Strings s) async {
    final ctrl = ref.read(crewListProvider.notifier);
    final state = ref.read(crewListProvider);
    final total = state is CrewListData ? state.crews.length : 0;

    final result = await showModalBottomSheet<CrewFilter>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext _) => FilterSheet(
        initial: ctrl.filter,
        strings: s,
        // 即時預覽的近似值；接真實後端時改為 count-only 查詢（T-052）
        countFor: (CrewFilter f) => (total > 0 ? total : 25) - f.activeCount * 2,
      ),
    );
    if (result != null) ctrl.applyFilter(result);
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.strings,
    required this.onSportChanged,
    required this.onOpenSheet,
    required this.onQueryChanged,
    required this.onQuerySubmitted,
    required this.onSearchFocusChanged,
    required this.onTimeWindowToggled,
  });

  final CrewFilter filter;
  final Strings strings;
  final void Function(Sport?) onSportChanged;
  final VoidCallback onOpenSheet;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onQuerySubmitted;
  final ValueChanged<bool> onSearchFocusChanged;
  final ValueChanged<TimeWindow> onTimeWindowToggled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = strings;
    return Container(
      color: c.surface,
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
            child: SearchField(
              value: filter.query,
              strings: strings,
              onChanged: onQueryChanged,
              onSubmitted: onQuerySubmitted,
              onFocusChanged: onSearchFocusChanged,
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              children: <Widget>[
                FilterChipButton(
                  label: s.sportAll,
                  selected: filter.sport == null,
                  onTap: () => onSportChanged(null),
                ),
                const SizedBox(width: Space.sm),
                ...Sport.values.expand(
                  (Sport sport) => <Widget>[
                    FilterChipButton(
                      label: sportLabel(sport, s),
                      selected: filter.sport == sport,
                      leading: Icon(
                        sportIcon(sport),
                        size: 14,
                        color:
                            filter.sport == sport ? c.textOnAccent : sportColor(sport, c),
                      ),
                      onTap: () => onSportChanged(filter.sport == sport ? null : sport),
                    ),
                    const SizedBox(width: Space.sm),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.lg),
            child: Row(
              children: <Widget>[
                FilterChipButton(
                  label: filter.city?.zh ?? s.filterCity,
                  selected: filter.city != null,
                  leading: Icon(
                    Icons.place_outlined,
                    size: 14,
                    color: filter.city != null ? c.textOnAccent : c.textSecondary,
                  ),
                  onTap: onOpenSheet,
                ),
                const SizedBox(width: Space.sm),
                // 「這週末」是最高頻的意圖，直接放在主列，
                // 不要求使用者先打開篩選面板。
                FilterChipButton(
                  label: s.whenWeekend,
                  selected: filter.timeWindow == TimeWindow.weekend,
                  leading: Icon(
                    Icons.weekend_outlined,
                    size: 14,
                    color: filter.timeWindow == TimeWindow.weekend
                        ? c.textOnAccent
                        : c.textSecondary,
                  ),
                  onTap: () => onTimeWindowToggled(
                    filter.timeWindow == TimeWindow.weekend
                        ? TimeWindow.any
                        : TimeWindow.weekend,
                  ),
                ),
                const SizedBox(width: Space.sm),
                FilterChipButton(
                  label: filter.styles.isEmpty
                      ? s.filterStyle
                      : s.filterActive(filter.styles.length),
                  selected: filter.styles.isNotEmpty,
                  leading: Icon(
                    Icons.tune_rounded,
                    size: 14,
                    color: filter.styles.isNotEmpty ? c.textOnAccent : c.textSecondary,
                  ),
                  onTap: onOpenSheet,
                ),
                const Spacer(),
                Text(
                  filter.sort == CrewSort.score ? s.sortByScore : s.sortByNext,
                  style: AppText.micro.copyWith(color: c.textTertiary),
                ),
                const SizedBox(width: Space.xs),
                Icon(Icons.swap_vert_rounded, size: 15, color: c.textTertiary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({required this.child});
  final Widget child;

  // 高度必須跟 _FilterBar 的實際內容一致：
  // 搜尋列 40 + 間距 8 + 運動 chip 42 + 間距 8 + 縣市列 36 + 底部 12
  static const _height = 152.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Material(
        color: context.colors.surface,
        elevation: overlapsContent ? 0.5 : 0,
        child: child,
      );

  @override
  bool shouldRebuild(_FilterHeaderDelegate old) => old.child != child;
}
