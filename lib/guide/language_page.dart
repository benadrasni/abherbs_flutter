import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/guide_search.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:flutter/material.dart';

const guideLanguagePhoneKey = ValueKey('guide-language-phone');

/// English names used to sort and to find a language by typing.
const guideLanguageEnglish = <String, String>{
  'ar_EG': 'Arabic',
  'bg_BG': 'Bulgarian',
  'cs_CZ': 'Czech',
  'da_DK': 'Danish',
  'de_DE': 'German',
  'en_US': 'English',
  'es_ES': 'Spanish',
  'et_EE': 'Estonian',
  'fa_IR': 'Persian',
  'fr_FR': 'French',
  'hi_IN': 'Hindi',
  'ko_KR': 'Korean',
  'hr_HR': 'Croatian',
  'id_ID': 'Indonesian',
  'it_IT': 'Italian',
  'he_IL': 'Hebrew',
  'lv_LV': 'Latvian',
  'lt_LT': 'Lithuanian',
  'hu_HU': 'Hungarian',
  'nl_NL': 'Dutch',
  'ja_JP': 'Japanese',
  'nb_NO': 'Norwegian',
  'pl_PL': 'Polish',
  'pt_PT': 'Portuguese',
  'ro_RO': 'Romanian',
  'ru_RU': 'Russian',
  'sk_SK': 'Slovak',
  'sl_SI': 'Slovenian',
  'sr_RS': 'Serbian',
  'sv_SE': 'Swedish',
  'tr_TR': 'Turkish',
  'fi_FI': 'Finnish',
  'uk_UA': 'Ukrainian',
  'zh_TW': 'Chinese',
};

const guideLanguageAliases = <String, List<String>>{
  'fa_IR': ['farsi'],
  'nb_NO': ['bokmal', 'nynorsk'],
  'zh_TW': ['mandarin', 'traditional chinese'],
};

class GuideLanguageOption {
  final String key;
  final String name;
  final String english;
  final List<String> aliases;

  const GuideLanguageOption({
    required this.key,
    required this.name,
    required this.english,
    this.aliases = const [],
  });
}

List<GuideLanguageOption> guideLanguageOptions(Map<String, String> names) {
  final options = <GuideLanguageOption>[
    for (final entry in names.entries)
      if (entry.value.isNotEmpty)
        GuideLanguageOption(
          key: entry.key,
          name: entry.value,
          english: guideLanguageEnglish[entry.key] ?? entry.value,
          aliases: guideLanguageAliases[entry.key] ?? const [],
        ),
  ];
  options.sort((a, b) {
    final byEnglish = foldSearch(a.english).compareTo(foldSearch(b.english));
    if (byEnglish != 0) return byEnglish;
    return a.key.compareTo(b.key);
  });
  return options;
}

bool guideLanguageShowsEnglish(GuideLanguageOption option) {
  return foldSearch(option.name) != foldSearch(option.english);
}

List<GuideLanguageOption> guideLanguageMatches(
  List<GuideLanguageOption> options,
  String query,
) {
  final needle = foldSearch(query);
  if (needle.isEmpty) return options;
  return [
    for (final option in options)
      if (_optionMatches(option, needle)) option,
  ];
}

bool guideLanguagePhoneMatches(String query, String title, String phoneName) {
  final needle = foldSearch(query);
  if (needle.isEmpty) return true;
  if (foldSearch(title).contains(needle)) return true;
  return phoneName.isNotEmpty && foldSearch(phoneName).contains(needle);
}

bool _optionMatches(GuideLanguageOption option, String needle) {
  if (foldSearch(option.name).contains(needle)) return true;
  if (foldSearch(option.english).contains(needle)) return true;
  if (foldSearch(option.key).contains(needle)) return true;
  for (final alias in option.aliases) {
    if (foldSearch(alias).contains(needle)) return true;
  }
  return false;
}

class GuideLanguagePage extends StatefulWidget {
  final String selectedKey;
  final String phoneName;
  final List<GuideLanguageOption> options;
  final Future<void> Function(String key) onChoose;

  const GuideLanguagePage({
    super.key,
    required this.selectedKey,
    required this.phoneName,
    required this.options,
    required this.onChoose,
  });

  @override
  State<GuideLanguagePage> createState() => _GuideLanguagePageState();
}

class _GuideLanguagePageState extends State<GuideLanguagePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _focus.addListener(_onChanged);
    _revealSaved();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _focus.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Brings a saved language into view. The phone choice stays put at the top.
  void _revealSaved() {
    final key = widget.selectedKey;
    if (key.isEmpty) return;
    final index = widget.options.indexWhere((option) => option.key == key);
    if (index <= 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      const phoneHeight = 76.0;
      const rowHeight = 60.0;
      final target = phoneHeight + rowHeight * index - 8;
      final max = _scroll.position.maxScrollExtent;
      if (max <= 0) return;
      _scroll.jumpTo(target.clamp(0.0, max));
    });
  }

  void _onChanged() {
    setState(() => _query = _controller.text);
  }

  Future<void> _choose(String key) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.onChoose(key);
    } catch (error) {
      debugPrint('guide language: $error');
      if (mounted) setState(() => _saving = false);
      return;
    }
    if (!mounted) return;
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final colors = GuideColors.of(context);
    final matches = guideLanguageMatches(widget.options, _query);
    final phone = guideLanguagePhoneMatches(
      _query,
      strings.guide_person_language_phone,
      widget.phoneName,
    );
    final phoneSelected = widget.selectedKey.isEmpty;
    return GuideTheme(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GuideBackButton(label: strings.guide_back),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.guide_person_language,
                      style: GuideType.question(colors),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      strings.guide_person_language_note,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: colors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              _FindField(
                controller: _controller,
                focusNode: _focus,
                active: _focus.hasFocus || _query.isNotEmpty,
                onClear: _controller.clear,
              ),
              Expanded(
                child: matches.isEmpty && !phone
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            strings.guide_person_language_empty,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: colors.ink3,
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        controller: _scroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(bottom: 24),
                        children: [
                          if (phone)
                            _PhoneChoice(
                              name: widget.phoneName,
                              selected: phoneSelected,
                              onPressed: _saving ? null : () => _choose(''),
                            ),
                          for (final option in matches)
                            _LanguageChoice(
                              option: option,
                              selected: option.key == widget.selectedKey,
                              onPressed:
                                  _saving ? null : () => _choose(option.key),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FindField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final VoidCallback onClear;

  const _FindField({
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final query = controller.text;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.cream,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? colors.moss : colors.rule,
            width: active ? 1.5 : 1,
          ),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, size: 20, color: colors.ink3),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autocorrect: false,
                  enableSuggestions: false,
                  cursorColor: colors.moss,
                  textInputAction: TextInputAction.search,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(fontSize: 16, color: colors.ink),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: strings.guide_person_language_find,
                    hintStyle: TextStyle(fontSize: 16, color: colors.ink3),
                  ),
                ),
              ),
              if (query.isNotEmpty)
                IconButton(
                  onPressed: onClear,
                  tooltip: strings.guide_person_language_clear,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 36,
                    height: 36,
                  ),
                  icon: Icon(Icons.close, size: 18, color: colors.ink3),
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneChoice extends StatelessWidget {
  final String name;
  final bool selected;
  final VoidCallback? onPressed;

  const _PhoneChoice({
    required this.name,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 8),
      child: Material(
        key: guideLanguagePhoneKey,
        color: selected ? colors.moss.withValues(alpha: 0.12) : colors.cream,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? colors.moss : colors.rule,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
            child: Row(
              children: [
                Icon(Icons.smartphone_outlined, size: 22, color: colors.moss),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.guide_person_language_phone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          height: 1.2,
                        ),
                      ),
                      if (name.isNotEmpty)
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: colors.ink3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check, size: 18, color: colors.moss),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageChoice extends StatelessWidget {
  final GuideLanguageOption option;
  final bool selected;
  final VoidCallback? onPressed;

  const _LanguageChoice({
    required this.option,
    required this.selected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final english = guideLanguageShowsEnglish(option) ? option.english : null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? colors.moss.withValues(alpha: 0.12) : null,
        border: BorderDirectional(
          bottom: BorderSide(color: colors.rule),
          start: BorderSide(
            color: selected ? colors.moss : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Material(
        key: ValueKey(option.key),
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(17, 11, 20, 11),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.name,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: colors.ink,
                          height: 1.2,
                        ),
                      ),
                      if (english != null)
                        Text(
                          english,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: colors.ink3,
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check, size: 18, color: colors.moss),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
