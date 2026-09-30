import 'dart:async';

import 'package:abherbs_flutter/guide/book_page.dart';
import 'package:abherbs_flutter/guide/find_page.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_theme.dart';
import 'package:abherbs_flutter/guide/guide_widgets.dart';
import 'package:abherbs_flutter/guide/seen_page.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

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
  int _accountTicket = 0;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DatabaseEvent>? _creditsSub;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;

  @override
  void initState() {
    super.initState();
    GuideAppearanceController.instance.apply(storedGuideAppearance());
    _authSub = Auth.subscribe((user) {
      unawaited(_onAccount(user));
    });
    _watchCredits();
    _loadColors();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) {
        final owned = purchases.any((purchase) {
          return purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased;
        });
        if (owned && mounted) setState(() {});
      },
      onError: (Object error) => debugPrint('guide purchases: $error'),
    );
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
    GuideTabs.show = null;
    GuideTabs.showSeen = null;
    GuideTabs.refreshSeen = null;
    _authSub?.cancel();
    _creditsSub?.cancel();
    _purchaseSub?.cancel();
    super.dispose();
  }

  void _go(int index) {
    setState(() {
      _opened.add(index);
      _index = index;
    });
    if (index == 2) _loadFinds();
  }

  /// Sign-in finishes after Find has drawn. Reload finds, then the account's
  /// credits and purchases, and draw those on the camera card.
  Future<void> _onAccount(User? user) async {
    final ticket = ++_accountTicket;
    _watchCredits();
    if (mounted) {
      setState(() {
        if (user == null) _credits = 0;
      });
    }
    final finds = _loadFinds();
    if (user != null) {
      try {
        await Auth.setUser();
      } catch (error) {
        debugPrint('guide account: $error');
      }
    }
    await finds;
    if (!mounted || ticket != _accountTicket || user == null) return;
    setState(() => _credits = Auth.credits);
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
    GuideTabs.show = (index) {
      if (mounted) _go(index);
    };
    GuideTabs.showSeen = () {
      if (mounted) _go(2);
    };
    GuideTabs.refreshSeen = () {
      if (mounted) _loadFinds();
    };
    return GuideTheme(
      navigationColor: (colors) => colors.cream,
      child: Scaffold(
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
        bottomNavigationBar: GuideBottomBar(
          index: _index,
          showAd: _index == 0 && Purchases.showsAds(),
          onSelect: _go,
        ),
      ),
    );
  }
}
