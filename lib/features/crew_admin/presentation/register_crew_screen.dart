import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/id_gen.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/primitives.dart';
import '../../crew_discovery/domain/crew_repository.dart';
import '../../crew_discovery/domain/entities.dart';
import '../../crew_discovery/presentation/crew_card.dart';
import 'admin_controller.dart';
import 'submission_guard.dart';

class RegisterCrewScreen extends ConsumerStatefulWidget {
  const RegisterCrewScreen({super.key});

  @override
  ConsumerState<RegisterCrewScreen> createState() => _RegisterCrewScreenState();
}

class _RegisterCrewScreenState extends ConsumerState<RegisterCrewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _homeBase = TextEditingController();
  final _schedule = TextEditingController();
  final _intro = TextEditingController();
  final _instagram = TextEditingController();
  final _contact = TextEditingController();

  /// honeypot：真人看不到，機器人會填。有值即靜默假成功（F-10）
  final _honeypot = TextEditingController();

  Sport _sport = Sport.run;
  City _city = City.taipei;
  final Set<StyleTag> _styles = <StyleTag>{};
  bool _consent = false;
  bool _submitting = false;
  bool _dirty = false;

  /// 冪等鍵在**進入表單時**產生，而非送出時。
  /// 這樣網路重試（同一次填寫）用同一把鑰匙，不會產生兩筆。
  late final String _idempotencyKey = IdGen().next('crew');

  @override
  void dispose() {
    for (final TextEditingController ctrl in <TextEditingController>[
      _name,
      _homeBase,
      _schedule,
      _intro,
      _instagram,
      _contact,
      _honeypot,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = ref.watch(stringsProvider);

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (bool didPop, Object? _) async {
        if (didPop || !_dirty) return;
        // 在 await 之前先取出 router。await 之後 context 可能已失效，
        // 這也是 use_build_context_synchronously 這條 lint 的用意——
        // 只檢查 mounted 並不足夠，因為那是 State 的 mounted，
        // 與這個 context 是否仍有效無關。
        final router = GoRouter.of(context);
        final leave = await _confirmLeave(s);
        if (leave) router.go('/admin');
      },
      child: Scaffold(
        backgroundColor: c.surfaceSunken,
        appBar: AppBar(
          title: Text(s.adminSubmitCrew),
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () async {
              final router = GoRouter.of(context);
              if (!_dirty || await _confirmLeave(s)) {
                router.go('/admin');
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          onChanged: () {
            if (!_dirty) setState(() => _dirty = true);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 120),
            children: <Widget>[
              DisclaimerNote(text: s.adminNoCrewHint),
              const SizedBox(height: Space.xl),
              _section(c, s.fieldCrewName),
              _field(
                controller: _name,
                hint: '例：晨光跑者 Dawn Runners',
                validator: (String? v) =>
                    (v == null || v.trim().length < 2) ? s.required : null,
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldSport),
              Wrap(
                spacing: Space.sm,
                children: Sport.values
                    .map(
                      (Sport sp) => FilterChipButton(
                        label: sportLabel(sp, s),
                        selected: _sport == sp,
                        leading: Icon(
                          sportIcon(sp),
                          size: 14,
                          color: _sport == sp ? c.textOnAccent : sportColor(sp, c),
                        ),
                        onTap: () => setState(() {
                          _sport = sp;
                          _dirty = true;
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldCity),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: City.all
                    .map(
                      (City ct) => FilterChipButton(
                        label: ct.zh,
                        selected: _city == ct,
                        onTap: () => setState(() {
                          _city = ct;
                          _dirty = true;
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldHomeBase),
              _field(
                controller: _homeBase,
                hint: '例：大安森林公園南側門',
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldSchedule, optional: true),
              _field(controller: _schedule, hint: '例：每週三 19:30、每週六 07:00'),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldStyles, optional: true),
              Wrap(
                spacing: Space.sm,
                runSpacing: Space.sm,
                children: StyleTag.all
                    .map(
                      (StyleTag t) => FilterChipButton(
                        label: t.zh,
                        selected: _styles.contains(t),
                        onTap: () => setState(() {
                          if (!_styles.remove(t)) _styles.add(t);
                          _dirty = true;
                        }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldIntro),
              _field(
                controller: _intro,
                hint: '介紹你的社團風格、適合的對象、團練方式…',
                maxLines: 4,
                validator: (String? v) =>
                    (v == null || v.trim().length < 10) ? '請至少寫 10 個字' : null,
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldInstagram),
              _field(
                controller: _instagram,
                hint: '@your_crew',
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              const SizedBox(height: Space.lg),
              _section(c, s.fieldContactName),
              _field(
                controller: _contact,
                hint: '例：小明',
                validator: (String? v) =>
                    (v == null || v.trim().isEmpty) ? s.required : null,
              ),
              // honeypot：視覺上完全隱藏，但仍在 widget tree 中
              Offstage(
                child: TextFormField(controller: _honeypot),
              ),
              const SizedBox(height: Space.xl),
              _consentRow(c, s),
              const SizedBox(height: Space.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_consent && !_submitting) ? _submit : null,
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
                    _submitting ? s.submitting : s.submit,
                    style: AppText.bodyStrong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(AppColors c, String label, {bool optional = false}) => Padding(
        padding: const EdgeInsets.only(bottom: Space.sm),
        child: Row(
          children: <Widget>[
            Text(label, style: AppText.bodyStrong.copyWith(color: c.textPrimary)),
            const SizedBox(width: Space.xs),
            if (!optional) Text('*', style: AppText.caption.copyWith(color: c.danger)),
          ],
        ),
      );

  Widget _field({
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        // 欄位級即時回饋（F-10 驗收條件 ①）
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: AppText.body,
        decoration: InputDecoration(hintText: hint),
      );

  Widget _consentRow(AppColors c, Strings s) => InkWell(
        onTap: () => setState(() => _consent = !_consent),
        borderRadius: BorderRadius.circular(Radii.md),
        child: Padding(
          padding: const EdgeInsets.all(Space.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Checkbox(
                value: _consent,
                activeColor: c.accentPrimary,
                onChanged: (bool? v) => setState(() => _consent = v ?? false),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: Space.md),
                  child: Text(
                    s.consentText,
                    style: AppText.caption.copyWith(color: c.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Future<bool> _confirmLeave(Strings s) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        content: Text(s.unsavedWarning, style: AppText.body),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(s.delete)),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    final s = ref.read(stringsProvider);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // honeypot 有值 → 靜默假成功，不讓機器人知道被擋
    if (SubmissionGuard.isBot(_honeypot.text)) {
      if (mounted) context.go('/admin');
      return;
    }

    setState(() => _submitting = true);
    final result = await ref.read(adminProvider.notifier).submitCrew(
          CrewDraft(
            name: _name.text.trim(),
            sport: _sport,
            city: _city,
            homeBase: _homeBase.text.trim(),
            intro: _intro.text.trim(),
            instagram: _instagram.text.trim(),
            contactName: _contact.text.trim(),
            regularSchedule: _schedule.text.trim().isEmpty ? null : _schedule.text.trim(),
            styles: _styles,
          ),
          _idempotencyKey,
        );

    if (!mounted) return;
    setState(() {
      _submitting = false;
      _dirty = false;
    });

    switch (result) {
      case Ok<Crew>():
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.submitSuccess)));
        context.go('/admin');
      case Err<Crew>(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.errorOf(failure.messageKey))));
    }
  }
}
