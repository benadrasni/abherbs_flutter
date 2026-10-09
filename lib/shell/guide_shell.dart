import 'dart:async';

import 'package:abherbs_flutter/book/book_page.dart';
import 'package:abherbs_flutter/find/find_page.dart';
import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/data/guide_favorites.dart';
import 'package:abherbs_flutter/person/guide_person.dart';
import 'package:abherbs_flutter/seen/guide_private_photos.dart';
import 'package:abherbs_flutter/seen/guide_seen.dart';
import 'package:abherbs_flutter/data/prefs.dart';
import 'package:abherbs_flutter/shell/guide_actions.dart';
import 'package:abherbs_flutter/shell/app_version.dart';
import 'package:abherbs_flutter/shell/app_version_check.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/shell/version_gate.dart';
import 'package:abherbs_flutter/seen/seen_page.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

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
  int _favoriteTicket = 0;
  GuideListCover? _favorites;
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
  String? _seenWatchUid;
  bool _seenLoadActive = false;
  bool _seenReloadQueued = false;
  VersionPrompt _versionPrompt = VersionPrompt.none;
  int? _storeBuild;
  int _dismissedStore = 0;
  bool _versionBusy = false;

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
    Purchases.namesRevision.addListener(_onNames);
    unawaited(guideGuestHasFreeName());
    _authSub = Auth.subscribe((user) {
      unawaited(_onAccount(user));
    });
    guideMonthCount.addListener(_onMonth);
    guideFavoriteIds.addListener(_onFavoriteIds);
    _watchQuota();
    _watchSeenRemote();
    _loadColors();
    unawaited(_checkVersion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (_languageCode == code) return;
    _languageCode = code;
    _loadLists();
    unawaited(_refreshFavoriteCover());
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
    GuideTabs.openPerson = null;
    GuideTabs.unconfirmed.value = 0;
    guideGuestFreeRemaining.removeListener(_onGuestFree);
    Purchases.namesRevision.removeListener(_onNames);
    guideMonthCount.removeListener(_onMonth);
    guideFavoriteIds.removeListener(_onFavoriteIds);
    watchGuideFavorites(null);
    _authSub?.cancel();
    _quotaSub?.cancel();
    _seenRemote?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(syncGuidePrivatePhotos());
    unawaited(_checkVersion());
    if (_opened.contains(2)) unawaited(_loadSeen());
  }

  /// A failed fetch keeps a remembered floor closed. The shell only shows
  /// the soft banner. The hard page is drawn over the navigator.
  Future<void> _checkVersion() async {
    if (_versionBusy) return;
    _versionBusy = true;
    try {
      final build = await readAppBuildNumber();
      if (!mounted) return;
      final fresh = decideVersion(await readFreshVersionFacts(build));
      await persistVersionDecision(fresh);
      VersionGateController.instance.apply(
        fresh.prompt == VersionPrompt.block
            ? VersionPrompt.block
            : VersionPrompt.none,
      );
      if (!mounted) return;
      var prompt = fresh.prompt == VersionPrompt.block
          ? VersionPrompt.none
          : fresh.prompt;
      final store = fresh.storeBuild;
      if (prompt == VersionPrompt.banner &&
          store != null &&
          store == _dismissedStore) {
        prompt = VersionPrompt.none;
      }
      setState(() {
        _versionPrompt = prompt;
        _storeBuild = store;
      });
    } catch (error) {
      debugPrint('version check: $error');
    } finally {
      _versionBusy = false;
    }
  }

  void _dismissVersionBanner() {
    final store = _storeBuild;
    if (store != null) {
      _dismissedStore = store;
      unawaited(Prefs.setInt(keyVersionBannerDismissed, store));
    }
    setState(() => _versionPrompt = VersionPrompt.none);
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
    GuideTabs.index = index;
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
    GuideTabs.index = 1;
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

  void _onNames() {
    if (!mounted) return;
    setState(() {});
    if (Purchases.namesReady && Purchases.syncsSeenPhotos()) {
      unawaited(syncGuidePrivatePhotos());
    }
  }

  /// Sign-in finishes after Find has drawn. The name meter follows the
  /// account record at once. The find list and the notebook load after that.
  Future<void> _onAccount(User? user) async {
    final ticket = ++_accountTicket;
    _watchQuota();
    watchGuideFavorites(user);
    unawaited(_refreshFavoriteCover());
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
    if (!mounted || ticket != _accountTicket) return;
    setState(() {});
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

  void _onFavoriteIds() {
    unawaited(_refreshFavoriteCover());
  }

  Future<void> _refreshFavoriteCover() async {
    final code = _languageCode;
    if (code == null) return;
    final ticket = ++_favoriteTicket;
    if (Auth.appUser == null || guideFavoriteIds.value.isEmpty) {
      if (!mounted || ticket != _favoriteTicket) return;
      if (_favorites != null) setState(() => _favorites = null);
      return;
    }
    try {
      final cover = await loadGuideFavoriteCover(code);
      if (!mounted || ticket != _favoriteTicket) return;
      setState(() => _favorites = cover);
    } catch (error) {
      debugPrint('guide favorites: $error');
      if (!mounted || ticket != _favoriteTicket) return;
      if (_favorites != null) setState(() => _favorites = null);
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
    GuideTabs.openPerson = openGuideAccount;
    GuideTabs.index = _index;
    final prompt = _versionPrompt;
    final wide = GuideWindow.of(context).wide;
    final showAd = (_index == 0 || _index == 1) && Purchases.showsAds();
    final pages = Column(
      children: [
        if (prompt == VersionPrompt.banner)
          VersionBanner(
            onUpdate: () => openAppUpdate(requiredUpdate: false),
            onDismiss: _dismissVersionBanner,
          ),
        Expanded(
          child: IndexedStack(
            index: _index,
            sizing: StackFit.expand,
            children: [
              FindPage(
                colorCounts: _colorCounts,
                lists: _lists,
                favorites: _favorites,
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
                      favorites: _favorites,
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
                      fieldGuide: Purchases.syncsSeenPhotos(),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
    return GuideTheme(
      navigationColor: (colors) => colors.cream,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: guideWithRail(
            context,
            showAd: wide && showAd,
            onSelect: _go,
            child: pages,
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : GuideBottomBar(
                index: _index,
                showAd: showAd,
                onSelect: _go,
              ),
      ),
    );
  }
}
