import '../../../core/utils/result.dart';
import 'entities.dart';

/// domain 層純 Dart：**零 flutter import**（由 harness 的 layering 檢查強制）。
abstract interface class CrewRepository {
  /// SWR：先 yield 快取（isStale=true），再 yield 網路結果。
  Stream<Result<CrewPage>> watchCrews(CrewFilter filter, {Cursor? after});

  Future<Result<CrewDetail>> getBySlug(String slug);

  Future<Result<List<Crew>>> getByIds(List<String> ids);

  /// 團長端
  Future<Result<Crew>> submitCrew(CrewDraft draft, {required String idempotencyKey});

  Future<Result<Session>> createSession(SessionDraft draft,
      {required String idempotencyKey});

  Future<Result<void>> deleteSession(String sessionId);

  Future<Result<Crew?>> myCrew(String ownerId);
}

class CrewDraft {
  const CrewDraft({
    required this.name,
    required this.sport,
    required this.city,
    required this.homeBase,
    required this.intro,
    required this.instagram,
    required this.contactName,
    this.regularSchedule,
    this.styles = const <StyleTag>{},
  });

  final String name;
  final Sport sport;
  final City city;
  final String homeBase;
  final String intro;
  final String instagram;
  final String contactName;
  final String? regularSchedule;
  final Set<StyleTag> styles;
}

class SessionDraft {
  const SessionDraft({
    required this.crewId,
    required this.title,
    required this.kind,
    required this.startsAt,
    required this.locationName,
    this.endsAt,
  });

  final String crewId;
  final String title;
  final SessionKind kind;
  final DateTime startsAt;
  final DateTime? endsAt;
  final String locationName;
}
