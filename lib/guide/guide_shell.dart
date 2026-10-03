import 'dart:async';

import 'package:abherbs_flutter/guide/book_page.dart';
import 'package:abherbs_flutter/guide/find_page.dart';
import 'package:abherbs_flutter/guide/guide_camera.dart';
import 'package:abherbs_flutter/guide/guide_data.dart';
import 'package:abherbs_flutter/guide/guide_person.dart';
import 'package:abherbs_flutter/guide/guide_private_photos.dart';
import 'package:abherbs_flutter/guide/guide_seen.dart';
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

class _GuideShellState extends State<GuideShell> with WidgetsBindingObserver {
  final Set<int> _opened = {0};
  int _index = 0;
  String? _languageCode;
  int _listTicket = 0;
  int _findTicket = 0;
  int _seenTicket = 0;
  int _unconfirmedTicket = 0;
  String? _seenUid;
  bool _unconfirmedLoaded = false;
  Map<String, int>? _colorCounts;
  List<GuideListCover>? _lists;
  GuideBookSegment _bookSegment = GuideBookSegment.families;
  List<GuideFind>? _finds;
  List<GuideSeenFind>? _notebook;
  int _accountTicket = 0;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DatabaseEvent>? _quotaSub;
  StreamSubscription<DatabaseEvent>? _seenRemote;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  String? _seenWatchUid;
  bool _seenLoadActive = false;
  bool _seenReloadQueued = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    guidePrivatePhotoFetch = fetchGuidePrivatePhoto;
    guideSyncPrivatePhotos = syncGuidePrivatePhotos;
    guideDeletePrivatePhotos = deleteGuidePrivatePhotos;
    guideSkipPrivatePhoto = skipGuidePrivatePhoto;
    GuideAppearanceController.instance.apply(storedGuideAppearance());
    guideGuestFreeRemaining.value = guideGuestFreeRemembered();
    guideGuestFreeRemaining.addListener(_onGuestFree);
    unawaited(guideGuestHasFreeName());
    _authSub = Auth.subscribe((user) {
      unawaited(_onAccount(user));
    });
    guideMonthCount.addListener(_onMonth);
    _watchQuota();
    _watchSeenRemote();
    _loadColors();
    _purchaseSub = InAppPurchase.instance.purchaseStream.listen(
      (purchases) {
        final owned = purchases.any((purchase) {
          return purchase.status == PurchaseStatus.restored ||
              purchase.status == PurchaseStatus.purchased;
        });
        if (owned && mounted) {
          setState(() {});
          unawaited(syncGuidePrivatePhotos());
        }
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
    if (_opened.contains(2)) {
      _loadSeen();
    } else {
      _loadUnconfirmed();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GuideTabs.show = null;
    GuideTabs.showSeen = null;
    GuideTabs.refreshSeen = null;
    GuideTabs.unconfirmed.value = 0;
    guideGuestFreeRemaining.removeListener(_onGuestFree);
    guideMonthCount.removeListener(_onMonth);
    _authSub?.cancel();
    _quotaSub?.cancel();
    _seenRemote?.cancel();
    _purchaseSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(syncGuidePrivatePhotos());
    if (_opened.contains(2)) unawaited(_loadSeen());
  }

  /// Keeps the signed-in notebook synced. An active listener is what writes
  /// a review's new status into the on-disk copy.
  void _watchSeenRemote() {
    final uid = guideNotebookUser()?.uid;
    if (uid == _seenWatchUid && _seenRemote != null) return;
    _seenRemote?.cancel();
    _seenRemote = null;
    _seenWatchUid = uid;
    if (uid == null) return;
    _seenRemote = privateObservationsReference
        .child(uid)
        .child(firebaseObservationsByDate)
        .child(firebaseAttributeList)
        .onValue
        .listen((_) {
      guidePrivatePhotosChanged();
      if (_opened.contains(2)) unawaited(_loadSeen());
    }, onError: (Object error) {
      debugPrint('guide seen: $error');
    });
  }

  void _go(int index) {
    setState(() {
      _opened.add(index);
      _index = index;
    });
    if (index == 2) {
      _loadFinds();
      _loadSeen();
    }
  }

  /// Find’s All lists opens Book on the lists of flowers.
  void _openLists() {
    setState(() {
      _bookSegment = GuideBookSegment.lists;
      _opened.add(1);
      _index = 1;
    });
  }

  void _onGuestFree() {
    if (mounted) setState(() {});
  }

  void _onMonth() {
    if (mounted) setState(() {});
  }

  /// Sign-in finishes after Find has drawn. Reload finds, then the account's
  /// photo-name meter, and draw that on the camera card.
  Future<void> _onAccount(User? user) async {
    final ticket = ++_accountTicket;
    _watchQuota();
    _watchSeenRemote();
    _resetSeenForUser();
    if (user == null) guideMonthCount.value = GuideMonthCount.empty;
    if (mounted) setState(() {});
    final finds = _loadFinds();
    final seen = _opened.contains(2) ? _loadSeen() : _loadUnconfirmed();
    if (user != null) {
      try {
        await Auth.setUser();
      } catch (error) {
        debugPrint('guide account: $error');
      }
    }
    await finds;
    await seen;
    if (!mounted || ticket != _accountTicket) return;
    await guideGuestHasFreeName();
    if (!mounted || ticket != _accountTicket) return;
    if (user != null) {
      unawaited(syncGuidePrivatePhotos());
      final count = await loadGuideMonthCount();
      if (!mounted || ticket != _accountTicket) return;
      if (guideMonthCount.value != count) guideMonthCount.value = count;
    }
    setState(() {});
  }

  void _watchQuota() {
    _quotaSub?.cancel();
    _quotaSub = null;
    final uid = Auth.appUser?.uid;
    if (uid == null) {
      guideMonthCount.value = GuideMonthCount.empty;
      return;
    }
    _quotaSub =
        rootReference.child(firebasePhotoQuota).child(uid).onValue.listen(
      (event) {
        final next = guideMonthCountFrom(event.snapshot.value, DateTime.now());
        if (guideMonthCount.value == next) return;
        guideMonthCount.value = next;
      },
      onError: (Object error) => debugPrint('guide month: $error'),
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

  void _resetSeenForUser() {
    final uid = guideNotebookUser()?.uid;
    if (uid == _seenUid) return;
    _seenUid = uid;
    _unconfirmedLoaded = false;
    ++_unconfirmedTicket;
    GuideTabs.unconfirmed.value = 0;
    if (_notebook == null) return;
    _notebook = null;
    if (mounted) setState(() {});
  }

  Future<void> _loadUnconfirmed() async {
    if (_notebook != null || _unconfirmedLoaded) return;
    final uid = guideNotebookUser()?.uid;
    _seenUid = uid;
    final ticket = ++_unconfirmedTicket;
    try {
      final count = await loadGuideUnconfirmedCount();
      if (!mounted || ticket != _unconfirmedTicket || _notebook != null) {
        return;
      }
      if (guideNotebookUser()?.uid != uid) return;
      _unconfirmedLoaded = true;
      GuideTabs.unconfirmed.value = count;
    } catch (error) {
      debugPrint('guide unconfirmed: $error');
    }
  }

  Future<void> _loadSeen() async {
    if (_seenLoadActive) {
      _seenReloadQueued = true;
      return;
    }
    _seenLoadActive = true;
    try {
      var spins = 0;
      do {
        _seenReloadQueued = false;
        await _loadSeenBody();
        spins++;
      } while (_seenReloadQueued && spins < 3);
    } finally {
      _seenLoadActive = false;
    }
  }

  Future<void> _loadSeenBody() async {
    final code = _languageCode;
    if (code == null) return;
    _seenUid = guideNotebookUser()?.uid;
    final ticket = ++_seenTicket;
    ++_unconfirmedTicket;
    try {
      final finds = await loadGuideSeen(code);
      if (!mounted || ticket != _seenTicket) return;
      setState(() => _notebook = finds);
      GuideTabs.unconfirmed.value = guideUnconfirmedTotal(finds);
    } catch (error) {
      debugPrint('guide seen: $error');
      if (!mounted || ticket != _seenTicket) return;
      if (_notebook == null) {
        setState(() => _notebook = []);
        GuideTabs.unconfirmed.value = 0;
      }
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
      if (!mounted) return;
      _loadFinds();
      _loadSeen();
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
                allowance: guideCameraLiveAllowance(
                  guestFree: guideGuestFreeRemaining.value,
                ),
                onOpenBook: _openLists,
                onOpenSeen: () => _go(2),
              ),
              _opened.contains(1)
                  ? BookPage(
                      lists: _lists,
                      segment: _bookSegment,
                      onSegment: (segment) {
                        if (_bookSegment == segment) return;
                        setState(() => _bookSegment = segment);
                      },
                      onOpenFind: () => _go(0),
                    )
                  : const SizedBox.shrink(),
              _opened.contains(2)
                  ? SeenPage(
                      finds: _notebook,
                      signedIn: Auth.appUser != null,
                      fieldGuide: Purchases.hasFieldGuide(),
                    )
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
