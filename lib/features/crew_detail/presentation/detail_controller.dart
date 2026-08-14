import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/utils/result.dart';
import '../../crew_discovery/domain/entities.dart';

/// family provider：以 slug 為 key，天然支援多個詳情頁同時存在
final crewDetailProvider =
    FutureProvider.autoDispose.family<CrewDetail, String>((Ref ref, String slug) async {
  final repo = ref.watch(crewRepositoryProvider);
  final result = await repo.getBySlug(slug);
  return switch (result) {
    Ok<CrewDetail>(:final value) => value,
    Err<CrewDetail>(:final failure) => throw failure,
  };
});
