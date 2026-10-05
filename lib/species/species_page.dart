import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/camera/guide_camera.dart';
import 'package:abherbs_flutter/data/guide_data.dart';
import 'package:abherbs_flutter/data/guide_results.dart';
import 'package:abherbs_flutter/species/guide_species.dart';
import 'package:abherbs_flutter/shell/guide_theme.dart';
import 'package:abherbs_flutter/shell/guide_widgets.dart';
import 'package:abherbs_flutter/species/schema_page.dart';
import 'package:abherbs_flutter/camera/outside_page.dart';
import 'package:abherbs_flutter/person/sign_in_page.dart';
import 'package:abherbs_flutter/offline/offline.dart';
import 'package:abherbs_flutter/person/authentication.dart';
import 'package:abherbs_flutter/species/fullscreen.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:exif/exif.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

typedef GuideImageBuilder = Widget Function(
  String path,
  BoxFit fit,
  double width,
  double height,
);

typedef GuideVideoBuilder = Widget Function(GuideVideo video);

Widget guideSpeciesImage(
  String path,
  BoxFit fit,
  double width,
  double height,
) {
  return Builder(
    builder: (context) => getImage(
      path,
      ColoredBox(color: GuideColors.of(context).paper2),
      width: width,
      height: height,
      fit: fit,
    ),
  );
}

/// The guide species page. A one-plant notification uses this route.
MaterialPageRoute<void> guideSpeciesRoute(
  String name, {
  GuideCameraPending? pending,
  Future<void> Function()? onConfirmPending,
  Future<void> Function()? onUndoPending,
  Future<void> Function(String name)? onRetargetPending,
  VoidCallback? onSearchBook,
}) {
  return MaterialPageRoute<void>(
    settings: const RouteSettings(name: guideSpeciesRouteName),
    builder: (context) => GuideSpeciesPage(
      name: name,
      pending: pending,
      load: (languageCode) => loadGuideSpecies(name, languageCode),
      onShowSeen: GuideTabs.showSeen,
      onConfirmPending: onConfirmPending,
      onUndoPending: onUndoPending,
      onRetargetPending: onRetargetPending,
      onSearchBook: onSearchBook,
    ),
  );
}

/// A notification for one plant. An empty name opens nothing.
MaterialPageRoute<void>? guideNotificationPlantRoute(String? name) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty) return null;
  return guideSpeciesRoute(trimmed);
}

Future<void> openGuidePlant(
  BuildContext context,
  String name, {
  GuideCameraPending? pending,
  Future<void> Function()? onConfirmPending,
  Future<void> Function()? onUndoPending,
  Future<void> Function(String name)? onRetargetPending,
  VoidCallback? onSearchBook,
}) {
  unawaited(
    FirebaseAnalytics.instance
        .logSelectContent(contentType: 'plant', itemId: name)
        .catchError((Object error) => debugPrint('guide species: $error')),
  );
  return Navigator.push(
    context,
    guideSpeciesRoute(
      name,
      pending: pending,
      onConfirmPending: onConfirmPending,
      onUndoPending: onUndoPending,
      onRetargetPending: onRetargetPending,
      onSearchBook: onSearchBook,
    ),
  );
}

class GuideSpeciesPage extends StatefulWidget {
  final String name;
  final GuideSpecies? initial;
  final Future<GuideSpecies?> Function(String languageCode) load;
  final Future<void> Function(GuideSeenDraft draft)? saveSeen;
  final Future<GuideSeenPhoto?> Function(String plant)? pickPhoto;

  /// Replaces the notebook check in tests. True is a signed-in account or
  /// the anonymous guest. False opens sign-in and does not create a guest.
  final bool Function()? isSignedIn;
  final Future<void> Function(BuildContext context)? onSignIn;
  final VoidCallback? onShowSeen;
  final GuideImageBuilder? imageBuilder;
  final GuideVideoBuilder? videoBuilder;
  final int? month;
  final GuideCameraPending? pending;
  final Future<void> Function()? onConfirmPending;
  final Future<void> Function()? onUndoPending;
  final Future<void> Function(String name)? onRetargetPending;
  final VoidCallback? onSearchBook;

  const GuideSpeciesPage({
    super.key,
    required this.name,
    required this.load,
    this.initial,
    this.saveSeen,
    this.pickPhoto,
    this.isSignedIn,
    this.onSignIn,
    this.onShowSeen,
    this.imageBuilder,
    this.videoBuilder,
    this.month,
    this.pending,
    this.onConfirmPending,
    this.onUndoPending,
    this.onRetargetPending,
    this.onSearchBook,
  });

  @override
  State<GuideSpeciesPage> createState() => _GuideSpeciesPageState();
}

class _GuideSpeciesPageState extends State<GuideSpeciesPage> {
  final Map<String, GlobalKey> _sectionKeys = {};
  GuideSpecies? _species;
  GuideSpeciesSeen? _seen;
  bool _started = false;
  bool _loading = true;
  bool _missing = false;
  bool _failed = false;
  bool _saving = false;
  bool _kept = false;
  bool _pendingBusy = false;
  int _ticket = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final initial = widget.initial;
    if (initial != null) {
      _species = initial;
      _seen = initial.seen;
      _loading = false;
      _bindKeys(initial);
      return;
    }
    _load();
  }

  int get _month => widget.month ?? DateTime.now().month;

  Future<void> _load() async {
    final ticket = ++_ticket;
    final languageCode = Localizations.localeOf(context).languageCode;
    try {
      final species = await widget.load(languageCode);
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _species = species;
        _seen = species?.seen;
        _missing = species == null;
        _failed = false;
        _loading = false;
        if (species != null) _bindKeys(species);
      });
    } catch (error) {
      debugPrint('guide species ${widget.name}: $error');
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _failed = false;
      _missing = false;
      _loading = true;
    });
    _load();
  }

  void _bindKeys(GuideSpecies species) {
    final ids = [
      for (final section in species.sections) section.id,
      'taxonomy',
      'distribution',
      'sightings',
    ];
    for (final id in ids) {
      _sectionKeys.putIfAbsent(id, GlobalKey.new);
    }
  }

  void _jump(String id) {
    final target = _sectionKeys[id]?.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      alignment: 0.16,
    );
  }

  bool _hasNotebook() {
    final check = widget.isSignedIn;
    if (check != null) return check();
    return guideNotebookUser() != null;
  }

  Future<void> _addSeen() async {
    if (_saving) return;
    if (!_hasNotebook()) {
      if (widget.isSignedIn == null) await Auth.startGuest();
      if (!mounted) return;
      if (!_hasNotebook()) {
        final signIn = widget.onSignIn ?? _openSignIn;
        await signIn(context);
        if (!mounted || !_hasNotebook()) return;
      }
    }
    if (!mounted) return;
    await _addPhoto();
  }

  Future<void> _addPhoto() async {
    setState(() => _saving = true);
    try {
      final pick = widget.pickPhoto ?? pickGuideSeenPhoto;
      final photo = await pick(widget.name);
      if (!mounted || photo == null || photo.relativePath.isEmpty) return;
      await _commit(photo, alreadySaving: true);
    } catch (error) {
      debugPrint('guide add seen ${widget.name}: $error');
      _showFailure();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _commit(
    GuideSeenPhoto photo, {
    bool alreadySaving = false,
  }) async {
    if (photo.relativePath.isEmpty) return;
    if (!alreadySaving) setState(() => _saving = true);
    final draft = GuideSeenDraft(
      plant: _species?.name ?? widget.name,
      when: photo.when,
      latitude: photo.latitude,
      longitude: photo.longitude,
      photoPath: photo.relativePath,
      fromPhoto: photo.fromPhoto,
    );
    try {
      final save = widget.saveSeen ?? saveGuideSeen;
      await save(draft);
      if (!mounted) return;
      setState(() => _seen = guideSeenAfterAdd(_seen, draft));
      GuideTabs.refreshSeen?.call();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          draft.fromPhoto
              ? S.of(context).guide_added_seen_photo
              : S.of(context).guide_added_seen,
        ),
      ));
    } catch (error) {
      debugPrint('guide save seen ${widget.name}: $error');
      _showFailure();
    } finally {
      if (mounted && !alreadySaving) setState(() => _saving = false);
    }
  }

  void _showFailure() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).guide_seen_failed)),
    );
  }

  void _showSeen() {
    final show = widget.onShowSeen;
    if (show == null) return;
    Navigator.popUntil(context, (route) => route.isFirst);
    show();
  }

  Future<void> _keepPending() async {
    if (_pendingBusy || _kept || widget.pending == null) return;
    setState(() => _pendingBusy = true);
    try {
      await widget.onConfirmPending?.call();
      if (!mounted) return;
      setState(() => _kept = true);
      GuideTabs.refreshSeen?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).guide_camera_confirmed)),
      );
    } finally {
      if (mounted) setState(() => _pendingBusy = false);
    }
  }

  Future<void> _undoPending() async {
    if (_pendingBusy || !_kept) return;
    setState(() => _pendingBusy = true);
    try {
      await widget.onUndoPending?.call();
      if (!mounted) return;
      setState(() => _kept = false);
      GuideTabs.refreshSeen?.call();
    } finally {
      if (mounted) setState(() => _pendingBusy = false);
    }
  }

  Future<void> _notThis() async {
    final pending = widget.pending;
    if (_pendingBusy || pending == null || _kept) return;
    final chosen = await showGuideOtherNames(
      context: context,
      candidates: pending.others,
      onSearch: widget.onSearchBook,
    );
    if (!mounted || chosen == null) return;
    final name = guideCameraSpeciesName(chosen);
    if (name == null) return;
    setState(() => _pendingBusy = true);
    try {
      await widget.onRetargetPending?.call(name);
      if (!mounted) return;
      unawaited(
        FirebaseAnalytics.instance
            .logSelectContent(contentType: 'plant', itemId: name)
            .catchError((Object error) => debugPrint('guide species: $error')),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).guide_outside_changed)),
      );
      final showSeen = widget.onShowSeen;
      final imageBuilder = widget.imageBuilder;
      final videoBuilder = widget.videoBuilder;
      final month = widget.month;
      final signedIn = widget.isSignedIn;
      final signIn = widget.onSignIn;
      final saveSeen = widget.saveSeen;
      final pickPhoto = widget.pickPhoto;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: guideSpeciesRouteName),
          builder: (context) => GuideSpeciesPage(
            name: name,
            load: (languageCode) => loadGuideSpecies(name, languageCode),
            onShowSeen: showSeen,
            imageBuilder: imageBuilder,
            videoBuilder: videoBuilder,
            month: month,
            isSignedIn: signedIn,
            onSignIn: signIn,
            saveSeen: saveSeen,
            pickPhoto: pickPhoto,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pendingBusy = false);
    }
  }

  Future<void> _share(GuideSpecies species) async {
    final title = species.hasVernacular ? species.label!.trim() : species.name;
    await SharePlus.instance.share(ShareParams(
      text: webPlantUrl(
        species.name,
        Localizations.localeOf(context).languageCode,
      ),
      subject: title,
    ));
  }

  void _openPhoto(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenPage(path),
        settings: const RouteSettings(name: 'FullScreen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GuideTheme(
      child: Scaffold(
        body: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final colors = GuideColors.of(context);
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.moss,
          ),
        ),
      );
    }
    if (_failed || _missing) {
      final strings = S.of(context);
      return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GuideBackButton(label: strings.guide_back),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _missing
                          ? strings.guide_species_missing
                          : strings.guide_species_failed,
                      style: TextStyle(color: colors.ink2),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _retry,
                        child: Text(strings.guide_results_retry),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    final page = _content(context, _species!);
    final pending = widget.pending;
    if (pending == null) return page;
    return Column(
      children: [
        Expanded(child: page),
        _PendingBar(
          pending: pending,
          species: _species!,
          kept: _kept,
          onKeep: _pendingBusy ? null : _keepPending,
          onNotIt: _pendingBusy ? null : _notThis,
          onUndo: _pendingBusy ? null : _undoPending,
        ),
      ],
    );
  }

  Widget _content(BuildContext context, GuideSpecies species) {
    final strings = S.of(context);
    final colors = GuideColors.of(context);
    final locale = Localizations.localeOf(context).toString();
    final notes = species.sectionById('trivia');
    final uses = species.sectionById('herbalism');
    final chips = <({String id, String label})>[
      if (notes != null) (id: 'trivia', label: strings.guide_notes),
      for (final section in species.sections)
        if (section.id != 'trivia' && section.id != 'herbalism')
          (id: section.id, label: _sectionTitle(strings, section.id)),
      if (uses != null) (id: 'herbalism', label: strings.plant_herbalism),
      (id: 'taxonomy', label: strings.guide_taxonomy),
      (id: 'distribution', label: strings.guide_distribution),
      (id: 'sightings', label: strings.guide_sightings),
    ];
    final range = guideFloweringRange(
      species.floweringFrom,
      species.floweringTo,
      (month) => DateFormat.MMMM(locale).format(DateTime(2000, month)),
    );
    return CustomScrollView(
      key: const Key('guide-species-scroll'),
      slivers: [
        SliverToBoxAdapter(
          child: _Gallery(
            species: species,
            image: _image,
            onBack: () => Navigator.maybePop(context),
            onShare:
                widget.pending == null || _kept ? () => _share(species) : null,
            onOpen: _openPhoto,
            videoBuilder: widget.videoBuilder,
          ),
        ),
        SliverToBoxAdapter(child: _NameBlock(species: species)),
        if (widget.pending == null && _seen != null)
          SliverToBoxAdapter(
            child: _SeenByYou(
              seen: _seen!,
              locale: locale,
              onPressed: _showSeen,
              image: _image,
            ),
          ),
        if (widget.pending == null)
          SliverToBoxAdapter(
            child: _AddSeenButton(saving: _saving, onPressed: _addSeen),
          ),
        SliverToBoxAdapter(
          child: _Facts(
            species: species,
            range: range,
            month: _month,
            locale: locale,
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _JumpDelegate(chips: chips, onJump: _jump),
        ),
        if (species.description != null)
          SliverToBoxAdapter(child: _Lead(text: species.description!)),
        if (notes != null)
          SliverToBoxAdapter(
            child: _Aside(
              key: _sectionKeys['trivia'],
              boxKey: const Key('guide-aside-trivia'),
              title: strings.guide_notes,
              text: notes.text,
              accent: colors.gold,
              top: 14,
            ),
          ),
        for (final section in species.sections)
          if (section.id != 'trivia' && section.id != 'herbalism')
            SliverToBoxAdapter(
              child: _Section(
                key: _sectionKeys[section.id],
                title: _sectionTitle(strings, section.id),
                text: section.text,
                warn: section.id == 'toxicity',
                onOpen: section.id == 'flower' || section.id == 'inflorescence'
                    ? () => _openSchema(context, species, section.id)
                    : null,
                linkKey: section.id == 'flower'
                    ? guideSchemaFlowerKey
                    : section.id == 'inflorescence'
                        ? guideSchemaInflorescenceKey
                        : null,
              ),
            ),
        if (uses != null)
          SliverToBoxAdapter(
            child: _Aside(
              key: _sectionKeys['herbalism'],
              boxKey: const Key('guide-aside-herbalism'),
              title: strings.plant_herbalism,
              text: uses.text,
              disclaimer: strings.plant_herbalism_disclaimer,
              accent: colors.moss,
              top: 16,
            ),
          ),
        SliverToBoxAdapter(
          child: _Taxonomy(
            key: _sectionKeys['taxonomy'],
            ranks: species.ranks,
          ),
        ),
        SliverToBoxAdapter(
          child: _Distribution(
            key: _sectionKeys['distribution'],
            path: species.mapPath,
          ),
        ),
        SliverToBoxAdapter(
          child: _Sightings(
            key: _sectionKeys['sightings'],
            sightings: species.sightings,
            locale: locale,
            image: _image,
            onOpen: _openPhoto,
          ),
        ),
        if (species.sources.isNotEmpty)
          SliverToBoxAdapter(child: _Sources(links: species.sources)),
        SliverToBoxAdapter(
          child: SizedBox(height: 24 + MediaQuery.paddingOf(context).bottom),
        ),
      ],
    );
  }

  Widget _image(String path, BoxFit fit, double width, double height) {
    final build = widget.imageBuilder ?? guideSpeciesImage;
    return build(path, fit, width, height);
  }
}

Future<void> _openSignIn(BuildContext context) {
  return openGuideSignIn(context);
}

void _openSchema(BuildContext context, GuideSpecies species, String id) {
  final back = species.hasVernacular ? species.label!.trim() : species.name;
  final flower = id == 'flower';
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      settings: RouteSettings(
        name: flower ? guideFlowerSchemaRouteName : guideInflorescenceRouteName,
      ),
      builder: (context) => flower
          ? GuideFlowerSchemaPage(backLabel: back)
          : GuideInflorescencePage(
              backLabel: back,
              types: species.inflorescenceTypes,
            ),
    ),
  );
}

String _sectionTitle(S strings, String id) {
  switch (id) {
    case 'flower':
      return strings.plant_flower;
    case 'inflorescence':
      return strings.plant_inflorescence;
    case 'fruit':
      return strings.plant_fruit;
    case 'leaf':
      return strings.plant_leaf;
    case 'stem':
      return strings.plant_stem;
    case 'habitat':
      return strings.plant_habitat;
    case 'toxicity':
      return strings.plant_toxicity;
    case 'herbalism':
      return strings.plant_herbalism;
    case 'trivia':
      return strings.guide_notes;
    default:
      return id;
  }
}

Future<GuideSeenPhoto?> pickGuideSeenPhoto(String plant) async {
  final user = await guideNotebookUserReady();
  if (user == null) return null;
  final access = await Permission.accessMediaLocation.status;
  if (!access.isGranted) {
    await Permission.accessMediaLocation.request();
  }
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: imageSizeScaleDown,
  );
  if (image == null) return null;
  final bytes = await image.readAsBytes();
  final exifData = await readExifFromBytes(bytes);
  final dateTag =
      exifData['EXIF DateTimeOriginal'] ?? exifData['Image DateTime'];
  final latitude = getLatitudeFromExif(
    exifData['GPS GPSLatitudeRef'],
    exifData['GPS GPSLatitude'],
  );
  final longitude = getLongitudeFromExif(
    exifData['GPS GPSLongitudeRef'],
    exifData['GPS GPSLongitude'],
  );
  final names = plant.toLowerCase().split(' ');
  var prefix = 'unknown_';
  if (names.length > 1 && names[0].isNotEmpty && names[1].isNotEmpty) {
    prefix = '${names[0][0]}${names[1][0]}_';
  }
  final dot = image.path.lastIndexOf('.');
  final slash = image.path.lastIndexOf('/');
  final suffix =
      dot > slash ? image.path.substring(dot) : defaultPhotoExtension;
  final filename = '$prefix${DateTime.now().millisecondsSinceEpoch}$suffix';
  final dir = '$storageObservations${user.uid}/${plant.replaceAll(' ', '_')}';
  final root = (await getApplicationDocumentsDirectory()).path;
  await Directory('$root/$dir').create(recursive: true);
  await File(image.path).copy('$root/$dir/$filename');
  return GuideSeenPhoto(
    relativePath: '$dir/$filename',
    when: getDateTimeFromExif(dateTag),
    latitude: latitude,
    longitude: longitude,
    fromPhoto: dateTag != null || latitude != 0 || longitude != 0,
  );
}

class _Gallery extends StatefulWidget {
  final GuideSpecies species;
  final GuideImageBuilder image;
  final VoidCallback onBack;
  final VoidCallback? onShare;
  final ValueChanged<String> onOpen;
  final GuideVideoBuilder? videoBuilder;

  const _Gallery({
    required this.species,
    required this.image,
    required this.onBack,
    required this.onShare,
    required this.onOpen,
    required this.videoBuilder,
  });

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  final PageController _page = PageController();

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final species = widget.species;
    final slides = <_Slide>[
      for (final path in species.photoPaths) _Slide.photo(path),
      if (species.platePath != null) _Slide.plate(species.platePath!),
      for (final video in species.videos) _Slide.video(video),
    ];
    if (slides.isEmpty) slides.add(const _Slide.photo(null));
    final plateIndex =
        species.platePath == null ? -1 : species.photoPaths.length;
    final videoIndex = species.videos.isEmpty
        ? -1
        : species.photoPaths.length + (species.platePath == null ? 0 : 1);
    final top = MediaQuery.paddingOf(context).top + 10;
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: 420,
      child: Stack(
        children: [
          PageView(
            controller: _page,
            children: [
              for (final slide in slides)
                slide.video == null
                    ? GestureDetector(
                        onTap: slide.path == null
                            ? null
                            : () => widget.onOpen(slide.path!),
                        child: ColoredBox(
                          color:
                              slide.plate ? colors.plateWell : colors.photoWell,
                          child: slide.path == null
                              ? const SizedBox.expand()
                              : widget.image(
                                  slide.path!,
                                  slide.plate ? BoxFit.contain : BoxFit.cover,
                                  width,
                                  420,
                                ),
                        ),
                      )
                    : ColoredBox(
                        color: colors.photoWell,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              bottom: _galleryPillInset +
                                  _galleryPillHeight +
                                  _galleryVideoGap,
                            ),
                            child: widget.videoBuilder?.call(slide.video!) ??
                                _YoutubePlantVideo(
                                  key: ValueKey(
                                    'guide-video-${slide.video!.id}',
                                  ),
                                  video: slide.video!,
                                ),
                          ),
                        ),
                      ),
            ],
          ),
          PositionedDirectional(
            top: top,
            start: 12,
            end: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _OverlayButton(
                  label: strings.guide_back,
                  onPressed: widget.onBack,
                  icon: const BackButtonIcon(),
                ),
                if (widget.onShare != null)
                  _OverlayButton(
                    label: strings.guide_share,
                    onPressed: widget.onShare!,
                    icon: const Icon(Icons.ios_share, size: 20),
                  ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 12,
            bottom: _galleryPillInset,
            child: Row(
              children: [
                for (final pill in _galleryPills(
                  species: species,
                  strings: strings,
                  plateIndex: plateIndex,
                  videoIndex: videoIndex,
                  go: _go,
                ))
                  pill,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _go(int index) {
    if (!_page.hasClients) return;
    _page.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }
}

const double _galleryPillInset = 12;
const double _galleryPillHeight = 30;
const double _galleryVideoGap = 8;

class _Slide {
  final String? path;
  final bool plate;
  final GuideVideo? video;

  const _Slide.photo(this.path)
      : plate = false,
        video = null;

  const _Slide.plate(this.path)
      : plate = true,
        video = null;

  const _Slide.video(this.video)
      : path = null,
        plate = false;
}

List<Widget> _galleryPills({
  required GuideSpecies species,
  required S strings,
  required int plateIndex,
  required int videoIndex,
  required void Function(int index) go,
}) {
  final pills = <Widget>[];
  void add(Widget pill) {
    if (pills.isNotEmpty) pills.add(const SizedBox(width: 6));
    pills.add(pill);
  }

  if (species.photoPaths.isNotEmpty) {
    add(_Pill(
      label: species.photoPaths.length == 1
          ? strings.guide_photo_one
          : strings.guide_photo_count(species.photoPaths.length),
      filled: false,
      onPressed: () => go(0),
    ));
  }
  if (plateIndex >= 0) {
    add(_Pill(
      label: strings.guide_plate,
      filled: false,
      onPressed: () => go(plateIndex),
    ));
  }
  if (videoIndex >= 0) {
    add(_Pill(
      key: const Key('guide-video-pill'),
      label: strings.guide_video,
      filled: false,
      onPressed: () => go(videoIndex),
    ));
  }
  return pills;
}

class _OverlayButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Widget icon;

  const _OverlayButton({
    required this.label,
    required this.onPressed,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Tooltip(
      message: label,
      child: Material(
        color: colors.wash,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: IconTheme(
              data: IconThemeData(color: colors.ink, size: 20),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

class _YoutubePlantVideo extends StatefulWidget {
  final GuideVideo video;

  const _YoutubePlantVideo({super.key, required this.video});

  @override
  State<_YoutubePlantVideo> createState() => _YoutubePlantVideoState();
}

class _YoutubePlantVideoState extends State<_YoutubePlantVideo> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.video.id,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
      ),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.close().catchError((Object error) {
      debugPrint('guide video: $error');
    }));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayer(
      controller: _controller,
      aspectRatio: 16 / 9,
      autoFullScreen: false,
      enableFullScreenOnVerticalDrag: false,
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }
}

class _NameBlock extends StatelessWidget {
  final GuideSpecies species;

  const _NameBlock({required this.species});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final named = species.hasVernacular;
    final title = named ? species.label!.trim() : species.name;
    final ranks = guideOrderFamilyLine(
      orderLabel: species.orderLabel,
      orderLatin: species.orderLatin,
      familyLabel: species.familyLabel,
      familyLatin: species.familyLatin,
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ranks.isNotEmpty) ...[
            Text(
              ranks,
              key: const Key('guide-order-family'),
              style: TextStyle(
                fontSize: 14,
                height: 1.35,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            title,
            style: named
                ? TextStyle(
                    fontFamily: GuideType.serif,
                    fontWeight: FontWeight.w500,
                    fontSize: 34,
                    letterSpacing: -0.85,
                    height: 1.05,
                    color: colors.ink,
                  )
                : GuideType.latin(colors).copyWith(fontSize: 34, height: 1.05),
          ),
          if (named) ...[
            const SizedBox(height: 6),
            Text.rich(TextSpan(
              style: GuideType.latin(colors).copyWith(fontSize: 18),
              children: [
                TextSpan(text: species.name),
                if (species.author != null)
                  TextSpan(
                    text: ' ${species.author}',
                    style: TextStyle(
                      fontFamily: GuideType.sans,
                      fontStyle: FontStyle.normal,
                      fontSize: 14,
                      color: colors.ink3,
                    ),
                  ),
              ],
            )),
          ] else if (species.author != null) ...[
            const SizedBox(height: 6),
            Text(
              species.author!,
              style: TextStyle(fontSize: 14, color: colors.ink3),
            ),
          ],
          if (species.names.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              S.of(context).guide_also(species.names.join(', ')),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.ink2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingBar extends StatelessWidget {
  final GuideCameraPending pending;
  final GuideSpecies species;
  final bool kept;
  final VoidCallback? onKeep;
  final VoidCallback? onNotIt;
  final VoidCallback? onUndo;

  const _PendingBar({
    required this.pending,
    required this.species,
    required this.kept,
    required this.onKeep,
    required this.onNotIt,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final time = guidePhotoMoment(context, pending.when);
    final name = species.hasVernacular ? species.label!.trim() : species.name;
    final file = pending.photoPath;
    final hasFile = file != null && file.isNotEmpty && File(file).existsSync();
    final ground = kept ? colors.mossFill : colors.ink;
    final foreground = kept ? Colors.white : colors.onInk;
    return ColoredBox(
      color: ground,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          14 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: hasFile
                    ? Image.file(File(file), fit: BoxFit.cover)
                    : const ColoredBox(color: Color(0xFF555555)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kept
                        ? strings.guide_camera_in_seen_as(name)
                        : strings.guide_camera_your_photo,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    kept
                        ? strings.guide_camera_confirmed_line(time)
                        : strings.guide_camera_pending_line(
                            time, pending.place),
                    style: TextStyle(
                      color: foreground,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (kept)
              _PendingButton(
                label: strings.guide_camera_undo,
                onPressed: onUndo,
                foreground: foreground,
                border: foreground.withValues(alpha: 0.4),
              )
            else ...[
              _PendingButton(
                label: strings.guide_camera_its_this,
                onPressed: onKeep,
                background: colors.madderFill,
                foreground: Colors.white,
              ),
              const SizedBox(width: 6),
              _PendingButton(
                label: strings.guide_camera_not_it,
                onPressed: onNotIt,
                foreground: foreground,
                border: foreground.withValues(alpha: 0.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PendingButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? background;
  final Color foreground;
  final Color? border;

  const _PendingButton({
    required this.label,
    required this.onPressed,
    required this.foreground,
    this.background,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: background,
        foregroundColor: foreground,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: border == null ? BorderSide.none : BorderSide(color: border!),
        ),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

/// Month and day. A find from another year also shows the year.
String guideSeenDate(DateTime when, String locale, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final format = when.year == today.year
      ? DateFormat.MMMd(locale)
      : DateFormat.yMMMd(locale);
  return format.format(when);
}

class _SeenByYou extends StatelessWidget {
  final GuideSpeciesSeen seen;
  final String locale;
  final VoidCallback onPressed;
  final GuideImageBuilder image;

  const _SeenByYou({
    required this.seen,
    required this.locale,
    required this.onPressed,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final last = seen.last;
    final when = last == null ? '' : guideSeenDate(last, locale);
    final detail = last == null
        ? ''
        : seen.count == 1
            ? strings.guide_seen_once(when)
            : strings.guide_seen_times(seen.count, when);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 0),
      child: Material(
        color: colors.cream,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.rule),
            ),
            padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: seen.photoPath == null
                        ? ColoredBox(color: colors.paper2)
                        : image(seen.photoPath!, BoxFit.cover, 36, 36),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        strings.guide_seen_by_you,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: colors.moss,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(
                          detail,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.2,
                            color: colors.ink,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddSeenButton extends StatelessWidget {
  final bool saving;
  final VoidCallback onPressed;

  const _AddSeenButton({required this.saving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: saving ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.ink,
              side: BorderSide(color: colors.rule),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontFamily: GuideType.sans,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text('+ ${strings.guide_add_seen}'),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              strings.guide_add_seen_hint,
              style: TextStyle(fontSize: 13, color: colors.ink3),
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final GuideSpecies species;
  final String range;
  final int month;
  final String locale;

  const _Facts({
    required this.species,
    required this.range,
    required this.month,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final height = guideHeightText(species.heightFrom, species.heightTo);
    final toxicity = guideCap(guideToxicityClassLabel(
      toxicityClass: species.toxicityClass,
      poisonous: strings.toxicity1,
      slight: strings.toxicity2,
      none: strings.guide_toxicity_none,
    ));
    final warn = species.toxicityClass == 1 || species.toxicityClass == 2;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.rule,
          border: Border.symmetric(
            horizontal: BorderSide(color: colors.rule),
          ),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _Fact(
                      label: strings.guide_height,
                      value: height.isEmpty ? '—' : height,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 3,
                    child: _Fact(
                      label: strings.plant_toxicity,
                      value: toxicity,
                      valueColor: warn ? colors.madder : null,
                      valueKey: const Key('guide-toxicity-value'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            ColoredBox(
              color: colors.paper,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 11, 20, 11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      range.isEmpty
                          ? strings.plant_flower
                          : strings.guide_flowers(range),
                      style: GuideType.eyebrow(colors),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (var m = 1; m <= 12; m++) ...[
                          if (m > 1) const SizedBox(width: 3),
                          Expanded(
                              child: _MonthCell(
                            month: m,
                            on: guideInFlower(
                              species.floweringFrom,
                              species.floweringTo,
                              m,
                            ),
                            now: m == month,
                            letter: DateFormat('MMMMM', locale)
                                .format(DateTime(2000, m)),
                          )),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Key? valueKey;
  final EdgeInsetsGeometry padding;

  const _Fact({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueKey,
    this.padding = const EdgeInsetsDirectional.fromSTEB(20, 11, 12, 11),
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return ColoredBox(
      color: colors.paper,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GuideType.eyebrow(colors)),
            const SizedBox(height: 2),
            Text(
              value,
              key: valueKey,
              style: TextStyle(
                fontFamily: GuideType.serif,
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: valueColor ?? colors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  final int month;
  final bool on;
  final bool now;
  final String letter;

  const _MonthCell({
    required this.month,
    required this.on,
    required this.now,
    required this.letter,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Container(
      key: ValueKey('guide-month-$month'),
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? colors.mossFill : colors.paper2,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: now ? colors.madder : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 10,
          color: on ? Colors.white : colors.ink3,
        ),
      ),
    );
  }
}

class _JumpDelegate extends SliverPersistentHeaderDelegate {
  final List<({String id, String label})> chips;
  final ValueChanged<String> onJump;

  _JumpDelegate({required this.chips, required this.onJump});

  @override
  double get minExtent => 54;

  @override
  double get maxExtent => 54;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = GuideColors.of(context);
    return ColoredBox(
      color: colors.paper,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.rule)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                _Pill(
                  label: chips[i].label,
                  filled: true,
                  onPressed: () => onJump(chips[i].id),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_JumpDelegate oldDelegate) {
    if (oldDelegate.chips.length != chips.length) return true;
    for (var i = 0; i < chips.length; i++) {
      if (oldDelegate.chips[i] != chips[i]) return true;
    }
    return false;
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onPressed;

  const _Pill({
    super.key,
    required this.label,
    required this.filled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Material(
      color: filled ? colors.cream : colors.wash,
      borderRadius: BorderRadius.circular(15),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: _galleryPillHeight,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: filled ? Border.all(color: colors.rule) : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _Lead extends StatelessWidget {
  final String text;

  const _Lead({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 0),
      child: _RichPlantText(
        text: text,
        style: TextStyle(
          fontSize: 15,
          height: 1.5,
          color: colors.ink2,
        ),
      ),
    );
  }
}

class _Aside extends StatelessWidget {
  final String title;
  final String text;
  final String? disclaimer;
  final Color accent;
  final double top;
  final Key? boxKey;

  const _Aside({
    super.key,
    required this.title,
    required this.text,
    required this.accent,
    required this.top,
    this.disclaimer,
    this.boxKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final rule = BorderSide(color: colors.rule);
    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, top, 20, 2),
      child: DecoratedBox(
        key: boxKey,
        decoration: BoxDecoration(
          color: colors.cream,
          border: BorderDirectional(
            top: rule,
            end: rule,
            bottom: rule,
            start: BorderSide(color: accent, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: GuideType.sans,
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              if (disclaimer != null) ...[
                const SizedBox(height: 6),
                Text(
                  disclaimer!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    color: colors.ink3,
                  ),
                ),
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 6),
              _RichPlantText(
                text: text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: colors.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String text;
  final bool warn;
  final VoidCallback? onOpen;
  final Key? linkKey;

  const _Section({
    super.key,
    required this.title,
    required this.text,
    required this.warn,
    this.onOpen,
    this.linkKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final body = _RichPlantText(
      text: text,
      style: TextStyle(
        fontSize: 15,
        height: 1.5,
        color: colors.body,
      ),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onOpen != null)
            GuideSchemaLink(
              key: linkKey,
              label: title,
              onPressed: onOpen!,
            )
          else
            Text(
              title,
              style: TextStyle(
                fontFamily: GuideType.serif,
                fontWeight: FontWeight.w500,
                fontSize: 19,
                color: colors.ink,
              ),
            ),
          const SizedBox(height: 6),
          if (warn)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: colors.madder, width: 3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(start: 10),
                child: body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }
}

class _RichPlantText extends StatelessWidget {
  final String text;
  final TextStyle style;

  const _RichPlantText({required this.text, required this.style});

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(
      style: style,
      children: [
        for (final run in guideTextRuns(text))
          TextSpan(
            text: run.text,
            style:
                run.bold ? const TextStyle(fontWeight: FontWeight.w700) : null,
          ),
      ],
    ));
  }
}

class _Taxonomy extends StatelessWidget {
  final List<GuideSpeciesRank> ranks;

  const _Taxonomy({super.key, required this.ranks});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(title: strings.guide_taxonomy, note: strings.guide_apg),
          const SizedBox(height: 6),
          for (final rank in ranks)
            Text.rich(TextSpan(
              style: TextStyle(
                fontSize: 14,
                height: 1.7,
                color: colors.ink,
              ),
              children: [
                TextSpan(
                  text: getTaxonLabel(context, rank.rank),
                  style: TextStyle(color: colors.ink3),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: rank.latin,
                  style: GuideType.latin(colors).copyWith(fontSize: 14),
                ),
                if (rank.vernacular != null && rank.vernacular!.isNotEmpty)
                  TextSpan(text: ' · ${rank.vernacular}'),
              ],
            )),
        ],
      ),
    );
  }
}

class _Distribution extends StatelessWidget {
  final String? path;

  const _Distribution({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            title: strings.guide_distribution,
            note: strings.guide_distribution_legend,
          ),
          if (path != null) ...[
            const SizedBox(height: 8),
            _MapImage(path: path!),
          ],
        ],
      ),
    );
  }
}

class _MapImage extends StatefulWidget {
  final String path;

  const _MapImage({required this.path});

  @override
  State<_MapImage> createState() => _MapImageState();
}

class _MapImageState extends State<_MapImage> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    if (_failed) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.rule),
          borderRadius: BorderRadius.circular(8),
        ),
        child: AspectRatio(
          aspectRatio: 2,
          child: FutureBuilder<File?>(
            future: Offline.getLocalFile(widget.path),
            builder: (context, snapshot) {
              final file = snapshot.data;
              if (file != null) {
                return Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fail(),
                );
              }
              if (snapshot.connectionState != ConnectionState.done) {
                return const ColoredBox(color: Colors.white);
              }
              return CachedNetworkImage(
                imageUrl: storageEndpoint + widget.path,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Colors.white),
                errorWidget: (_, __, ___) => _fail(),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _fail() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_failed) setState(() => _failed = true);
    });
    return const SizedBox.shrink();
  }
}

class _Sightings extends StatelessWidget {
  final List<GuideSighting> sightings;
  final String locale;
  final GuideImageBuilder image;
  final ValueChanged<String> onOpen;

  const _Sightings({
    super.key,
    required this.sightings,
    required this.locale,
    required this.image,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    final strings = S.of(context);
    final shown = sightings.take(9).toList();
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(
            title: strings.guide_sightings,
            note: shown.isEmpty
                ? null
                : strings.guide_sightings_count(sightings.length),
          ),
          const SizedBox(height: 6),
          if (shown.isEmpty)
            Text(
              strings.guide_sightings_empty,
              style: TextStyle(fontSize: 13, color: colors.ink3),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemCount: shown.length,
              itemBuilder: (context, index) {
                final sighting = shown[index];
                final when = sighting.when;
                final caption =
                    when == null ? null : DateFormat.yMMMM(locale).format(when);
                return GestureDetector(
                  onTap: () => onOpen(sighting.photoPath),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        image(sighting.photoPath, BoxFit.cover, 120, 120),
                        if (caption != null)
                          PositionedDirectional(
                            start: 4,
                            bottom: 4,
                            end: 4,
                            child: Align(
                              alignment: AlignmentDirectional.bottomStart,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colors.wash,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  child: Text(
                                    caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              strings.guide_sightings_hint,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: colors.ink3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Sources extends StatelessWidget {
  final List<GuideSourceLink> links;

  const _Sources({required this.links});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).plant_sources,
            style: TextStyle(
              fontFamily: GuideType.serif,
              fontWeight: FontWeight.w500,
              fontSize: 19,
              color: colors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var i = 0; i < links.length; i++) ...[
                if (i > 0)
                  Text(
                    ' · ',
                    style: TextStyle(fontSize: 13, color: colors.ink3),
                  ),
                GestureDetector(
                  onTap: () => launchURL(links[i].url),
                  child: Text(
                    links[i].label,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: colors.moss,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  final String title;
  final String? note;

  const _Heading({required this.title, this.note});

  @override
  Widget build(BuildContext context) {
    final colors = GuideColors.of(context);
    return Text.rich(TextSpan(
      style: TextStyle(
        fontFamily: GuideType.serif,
        fontWeight: FontWeight.w500,
        fontSize: 19,
        color: colors.ink,
      ),
      children: [
        TextSpan(text: title),
        if (note != null)
          TextSpan(
            text: '  $note',
            style: TextStyle(
              fontFamily: GuideType.sans,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.ink3,
            ),
          ),
      ],
    ));
  }
}
