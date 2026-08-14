import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/result.dart';
import '../../core/widgets/primitives.dart';
import '../crew_discovery/domain/entities.dart';
import '../crew_discovery/presentation/crew_card.dart';

final favoriteCrewsProvider = FutureProvider.autoDispose<List<Crew>>((Ref ref) async {
  final ids = ref.watch(favoritesProvider);
  if (ids.isEmpty) return const <Crew>[];
  final result = await ref.watch(crewRepositoryProvider).getByIds(ids.toList());
  return switch (result) {
    Ok<List<Crew>>(:final value) => value,
    Err<List<Crew>>() => const <Crew>[],
  };
});

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final now = ref.watch(clockProvider).now();
    final async = ref.watch(favoriteCrewsProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      appBar: AppBar(
        title: Text(s.navFavorites),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object _, StackTrace __) => EmptyStateView(
          icon: Icons.wifi_off_rounded,
          title: s.errorUnknown,
          hint: s.emptyNoResultHint,
        ),
        data: (List<Crew> crews) => crews.isEmpty
            ? EmptyStateView(
                icon: Icons.favorite_border_rounded,
                title: s.emptyNoFavorites,
                hint: s.emptyNoFavoritesHint,
                actionLabel: s.navDiscover,
                onAction: () => context.go('/'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(Space.lg),
                itemCount: crews.length,
                separatorBuilder: (BuildContext _, int __) =>
                    const SizedBox(height: Space.md),
                itemBuilder: (BuildContext context, int i) => CrewCard(
                  crew: crews[i],
                  now: now,
                  strings: s,
                  isFavorite: favorites.contains(crews[i].id),
                  onTap: () => context.go('/crews/${crews[i].slug}'),
                  onToggleFavorite: () =>
                      ref.read(favoritesProvider.notifier).toggle(crews[i].id),
                ),
              ),
      ),
    );
  }
}
