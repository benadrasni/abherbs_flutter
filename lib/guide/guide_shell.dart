import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/guide/book_page.dart';
import 'package:abherbs_flutter/guide/find_page.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/seen_page.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GuideShell extends StatefulWidget {
  const GuideShell({super.key});

  @override
  State<GuideShell> createState() => _GuideShellState();
}

class _GuideShellState extends State<GuideShell> {
  final Set<int> _opened = {0};
  int _index = 0;
  String? _languageCode;
  int _listTicket = 0;
  int _findTicket = 0;
  Map<String, int>? _colorCounts;
  List<GuideListCover>? _lists;
  List<GuideFind>? _finds;
  int _credits = Auth.credits;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DatabaseEvent>? _creditsSub;

  @override
  void initState() {
    super.initState();
    _authSub = Auth.subscribe((_) {
      _watchCredits();
      _loadFinds();
    });
    _watchCredits();
    _loadColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (_languageCode == code) return;
    _languageCode = code;
    _loadLists();
    _loadFinds();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _creditsSub?.cancel();
    super.dispose();
  }

  void _go(int index) {
    setState(() {
      _opened.add(index);
      _index = index;
    });
    if (index == 2) _loadFinds();
  }

  void _watchCredits() {
    _creditsSub?.cancel();
    _creditsSub = null;
    final uid = Auth.appUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _credits = 0);
      return;
    }
    _creditsSub = usersReference
        .child(uid)
        .child(firebaseAttributeCredits)
        .onValue
        .listen(
      (event) {
        final value = event.snapshot.value;
        final next = value is int ? value : (value is num ? value.toInt() : 0);
        if (!mounted) return;
        setState(() => _credits = next);
      },
      onError: (Object error) => debugPrint('guide credits: $error'),
    );
  }

  Future<void> _loadColors() async {
    try {
      final counts = await loadColorCounts();
      if (!mounted) return;
      setState(() => _colorCounts = counts);
    } catch (error) {
      debugPrint('guide colors: $error');
    }
  }

  Future<void> _loadLists() async {
    final code = _languageCode;
    if (code == null) return;
    final ticket = ++_listTicket;
    try {
      final lists = await loadGuideLists(code);
      if (!mounted || ticket != _listTicket) return;
      setState(() => _lists = lists);
    } catch (error) {
      debugPrint('guide lists: $error');
      if (!mounted || ticket != _listTicket) return;
      setState(() => _lists = []);
    }
  }

  Future<void> _loadFinds() async {
    final code = _languageCode;
    if (code == null) return;
    final ticket = ++_findTicket;
    try {
      final finds = await loadRecentFinds(code, limit: 40);
      if (!mounted || ticket != _findTicket) return;
      setState(() => _finds = finds);
    } catch (error) {
      debugPrint('guide finds: $error');
      if (!mounted || ticket != _findTicket) return;
      setState(() => _finds = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: GuidePalette.cream,
      ),
      child: Theme(
        data: guideTheme(),
        child: Scaffold(
          backgroundColor: GuidePalette.paper,
          body: SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _index,
              sizing: StackFit.expand,
              children: [
                FindPage(
                  colorCounts: _colorCounts,
                  lists: _lists,
                  finds: _finds,
                  credits: _credits,
                  onOpenBook: () => _go(1),
                  onOpenSeen: () => _go(2),
                ),
                _opened.contains(1)
                    ? BookPage(lists: _lists, onOpenFind: () => _go(0))
                    : const SizedBox.shrink(),
                _opened.contains(2)
                    ? SeenPage(finds: _finds)
                    : const SizedBox.shrink(),
              ],
            ),
          ),
          bottomNavigationBar: _Tabs(
            index: _index,
            onSelect: _go,
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;

  const _Tabs({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final items = [
      (S.of(context).guide_tab_find, Icons.center_focus_weak),
      (S.of(context).guide_tab_book, Icons.menu_book_outlined),
      (S.of(context).guide_tab_seen, Icons.article_outlined),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: GuidePalette.cream,
        border: Border(top: BorderSide(color: GuidePalette.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onSelect(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$2,
                          size: 24,
                          color: i == index
                              ? GuidePalette.moss
                              : GuidePalette.ink3,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].$1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                i == index ? FontWeight.w600 : FontWeight.w400,
                            color: i == index
                                ? GuidePalette.moss
                                : GuidePalette.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
