import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_gen.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_discovery/domain/crew_repository.dart';
import '../../crew_discovery/domain/entities.dart';
import 'admin_controller.dart';

class NewSessionScreen extends ConsumerStatefulWidget {
  const NewSessionScreen({super.key});

  @override
  ConsumerState<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends ConsumerState<NewSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();

  DateTime? _startsAt;
  DateTime? _endsAt;
  SessionKind _kind = SessionKind.regular;
  bool _submitting = false;

  late final String _idempotencyKey = IdGen().next('sess');

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);
    final state = ref.watch(adminProvider);
    final crew = state is AdminHasCrew ? state.crew : null;

    return Scaffold(
      backgroundColor: c.surfaceSunken,
      appBar: AppBar(
        title: Text(s.adminNewSession),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 120),
          children: <Widget>[
            _label(c, s.fieldSessionTitle),
            TextFormField(
              controller: _title,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: AppText.body,
              decoration: const InputDecoration(hintText: '例：Social Run'),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? s.required : null,
            ),
            const SizedBox(height: Space.lg),
            _label(c, s.fieldSessionKind),
            Wrap(
              spacing: Space.sm,
              children: SessionKind.values
                  .map(
                    (SessionKind k) => FilterChipButton(
                      label: sessionKindLabel(k, s),
                      selected: _kind == k,
                      onTap: () => setState(() => _kind = k),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: Space.lg),
            _label(c, s.fieldStartsAt),
            _dateTimeTile(
              c,
              _startsAt == null
                  ? '選擇日期與時間'
                  : '${TimeFormatter.md(_startsAt!)}（${TimeFormatter.weekday(_startsAt!, zh: true)}） ${TimeFormatter.hhmm(_startsAt!)}',
              _startsAt != null,
              () => _pickDateTime(isStart: true),
            ),
            const SizedBox(height: Space.lg),
            _label(c, s.fieldEndsAt, optional: true),
            _dateTimeTile(
              c,
              _endsAt == null
                  ? '未設定（預設 +2 小時）'
                  : '${TimeFormatter.md(_endsAt!)} ${TimeFormatter.hhmm(_endsAt!)}',
              _endsAt != null,
              () => _pickDateTime(isStart: false),
            ),
            const SizedBox(height: Space.lg),
            _label(c, s.fieldLocation),
            TextFormField(
              controller: _location,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: AppText.body,
              decoration: const InputDecoration(hintText: '例：大安森林公園南側門'),
              validator: (String? v) =>
                  (v == null || v.trim().isEmpty) ? s.required : null,
            ),
            const SizedBox(height: Space.xl),
            DisclaimerNote(text: s.disclaimer),
            const SizedBox(height: Space.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (crew == null || _submitting) ? null : () => _submit(crew.id),
                style: FilledButton.styleFrom(
                  backgroundColor: c.accentPrimary,
                  foregroundColor: c.textOnAccent,
                  disabledBackgroundColor: c.borderSubtle,
                  padding: const EdgeInsets.symmetric(vertical: Space.lg),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.md),
                  ),
                ),
                child: Text(
                  _submitting ? s.submitting : s.saveChanges,
                  style: AppText.bodyStrong,
                ),
              ),
            ),
            const SizedBox(height: Space.md),
            Center(
              child: Text(
                '公告活動可累積活躍度積分（+3）',
                style: AppText.micro.copyWith(color: c.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(AppColors c, String text, {bool optional = false}) => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Row(
          children: <Widget>[
            Text(text, style: AppText.bodyStrong.copyWith(color: c.textPrimary)),
            if (!optional) ...<Widget>[
              const SizedBox(width: Space.xs),
              Text('*', style: AppText.caption.copyWith(color: c.danger)),
            ],
          ],
        ),
      );

  Widget _dateTimeTile(AppColors c, String text, bool filled, VoidCallback onTap) =>
      Material(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Radii.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Space.lg,
              vertical: Space.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Radii.md),
              border: Border.all(color: c.borderSubtle),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.event_rounded, size: 18, color: c.textTertiary),
                const SizedBox(width: Space.md),
                Text(
                  text,
                  style: AppText.body.copyWith(
                    color: filled ? c.textPrimary : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Future<void> _pickDateTime({required bool isStart}) async {
    final now = ref.read(clockProvider).now();
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startsAt ?? now) : (_endsAt ?? _startsAt ?? now),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isStart ? (_startsAt ?? now) : now),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startsAt = picked;
        // 開始時間晚於結束時間時自動清除，避免產生無效資料
        if (_endsAt != null && !_endsAt!.isAfter(picked)) _endsAt = null;
      } else {
        _endsAt = picked;
      }
    });
  }

  Future<void> _submit(String crewId) async {
    final s = ref.read(stringsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_startsAt == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${s.fieldStartsAt}：${s.required}')));
      return;
    }
    // 資料庫有 check constraint (ends_at > starts_at)，UI 也擋一次
    if (_endsAt != null && !_endsAt!.isAfter(_startsAt!)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('結束時間必須晚於開始時間')));
      return;
    }

    setState(() => _submitting = true);
    final result = await ref.read(adminProvider.notifier).createSession(
          SessionDraft(
            crewId: crewId,
            title: _title.text.trim(),
            kind: _kind,
            startsAt: _startsAt!,
            endsAt: _endsAt,
            locationName: _location.text.trim(),
          ),
          _idempotencyKey,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    switch (result) {
      case Ok<Session>():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.sessionCreated)));
        context.go('/admin');
      case Err<Session>(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.errorOf(failure.messageKey))));
    }
  }
}
