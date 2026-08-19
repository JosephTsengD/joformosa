import 'package:flutter/material.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// 搜尋輸入框。
///
/// 刻意**不**在這裡做 debounce——那是 CrewListController 的職責。
/// 如果兩邊都做，延遲會疊加成 600ms，使用者會覺得卡；
/// 而且沒有人說得清楚實際延遲是多少。
///
/// 這個 widget 只負責：輸入、顯示清除鈕、把每次變更往上送。
class SearchField extends StatefulWidget {
  const SearchField({
    required this.value,
    required this.strings,
    required this.onChanged,
    required this.onSubmitted,
    super.key,
    this.onFocusChanged,
  });

  final String value;
  final Strings strings;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value);
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  void _onFocus() => widget.onFocusChanged?.call(_focus.hasFocus);

  @override
  void didUpdateWidget(SearchField old) {
    super.didUpdateWidget(old);
    // 外部（例如點選最近搜尋、或從網址還原）改變了值時同步進來。
    // 但不能無條件覆蓋，否則使用者打字打到一半會被自己的 state 打斷。
    if (widget.value != old.value && widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocus)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(
          color: _focus.hasFocus ? c.accentPrimary : c.borderSubtle,
          width: _focus.hasFocus ? 1.4 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Space.md),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, size: 18, color: c.textTertiary),
          const SizedBox(width: Space.sm),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.search,
              style: AppText.body.copyWith(color: c.textPrimary),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: widget.strings.searchHint,
                hintStyle: AppText.body.copyWith(color: c.textTertiary),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: widget.strings.searchClear,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _controller.clear();
                  widget.onChanged('');
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: Space.sm),
                  child: Icon(
                    Icons.cancel_rounded,
                    size: 17,
                    color: c.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 最近搜尋的下拉面板
class RecentSearchPanel extends StatelessWidget {
  const RecentSearchPanel({
    required this.entries,
    required this.strings,
    required this.onPick,
    required this.onRemove,
    required this.onClearAll,
    super.key,
  });

  final List<String> entries;
  final Strings strings;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(Space.lg, 0, Space.lg, Space.sm),
      padding: const EdgeInsets.symmetric(vertical: Space.sm),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.sm, Space.xs),
            child: Row(
              children: <Widget>[
                Text(
                  strings.searchRecent,
                  style: AppText.micro.copyWith(color: c.textTertiary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClearAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    strings.searchRecentClear,
                    style: AppText.micro.copyWith(color: c.accentPrimary),
                  ),
                ),
              ],
            ),
          ),
          ...entries.map(
            (String e) => InkWell(
              onTap: () => onPick(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Space.md,
                  vertical: Space.sm + 2,
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.history_rounded, size: 15, color: c.textTertiary),
                    const SizedBox(width: Space.sm),
                    Expanded(
                      child: Text(
                        e,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(color: c.textPrimary),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => onRemove(e),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: c.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
