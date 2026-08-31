# Agent notes — What's that flower?

Hobby Flutter app (`sk.ab.herbs`) plus Firebase catalog. Destination is a plant encyclopedia; the live product is a 4-step flower identifier with 1,413 species.

Read `README.md` and `docs/` before changing architecture or data shape.

## Repos and paths

- Workspace: `~/whatsthatflower` (`app`, `ingest`, `web` symlinks; `whatsthatflower.code-workspace`)
- App: this repo (`~/StudioProjects/abherbs_flutter`, also `~/whatsthatflower/app`)
- Ingest / indexes: `~/PycharmProjects/abherbs-auto` (`~/whatsthatflower/ingest`)
- Web: `~/WebstormProjects/abherbs-web` (`~/whatsthatflower/web`)
- Secrets and keystore: `~/Development/Keystore/` (stays outside the workspace)
- Incoming plants / job packets: `~/whatsthatflower/plants`
- Prepared photos: `~/whatsthatflower/storage/photos`
- Observation review downloads: `~/whatsthatflower/observations`
- WCVP cache: `~/whatsthatflower/wcvp`

The old native Android + Java indexer tree at `~/WebstormProjects/abherbs` is **not part of this project**. Leave it on disk for reference; do not treat it as a sibling to change or run.

Git remote: `https://github.com/benadrasni/abherbs_flutter`.

## Do not

- Commit `lib/keys.dart`, `lib/firebase_options.dart`, `android/keystore.properties`, `android/app/google-services.json`, `ios/fastlane/`, or any Admin / Play / App Store key.
- Print keystore passwords, API keys, or `.p8` / service-account JSON into chat or markdown.
- Rename a plant by writing only `plants_v2/{new}`. Headers, lists, search, translations, synonyms, and custom lists all key off the Latin name or numeric id.
- "Fix" the 4-step filter indexes as a side effect of encyclopedia work. They are the shipping identifier.
- Treat `sk.ab.herbsplus` as the current app.

## Conventions

- Flutter 3.47.2 / Dart 3.13.2. Match the existing style: `StatefulWidget`, Firebase `once()` / `keepSynced`, no extra state library. iOS uses Swift Package Manager (`enable-swift-package-manager: true`). Maps is `google_maps_flutter_ios_sdk10` (Maps SDK 10.x via SPM), not the default CocoaPods `google_maps_flutter_ios`.
- iOS uses the UIScene lifecycle (`FlutterSceneDelegate` in `Info.plist`; plugin registration in `AppDelegate.didInitializeImplicitFlutterEngine`).
- Version is `pubspec.yaml` `version: X.Y.Z+XYZ` (build number = version without dots). Bump both together for a store build.
- UI strings: edit `lib/l10n/intl_*.arb`, then `flutter pub run intl_utils:generate`.
- Filter key format: `color_habitat_petal_distribution` with empty slots allowed. Vocabulary is in `lib/filter/filter_utils.dart`.
- Plant photos are public HTTPS under `https://storage.googleapis.com/abherbs-resources/photos/`.
- English is the translation fallback except Czech → Slovak.
- Species English sources: `ingest/data/botanical_sources.json`. Reliable floras include Wikipedia, PFAF, RHS, Luontoportti, Missouri Plants, BOTANY.cz, and EPPO for names. When a web flora is useful, add it there for later plants.
- Never translate an English common name into another language. Vernacular `label` / `names` must come from a source in that language (Wikidata, that Wikipedia title, EPPO Global Database https://gd.eppo.int/, or a flora such as BOTANY.cz). If none exists, omit `label` and keep the Latin name.
- Adding a species: follow `ingest/ADD_PLANT.md`. Dry-run first; incremental live publish only when asked to add it to the database. Do not full-promote indexes for one plant. If no illustration id is given, look at available botanicalillustrations.org plates and pick the best representation of the plant.

## Firebase

- Project `abherbs-backend`, RTDB `https://abherbs-backend.firebaseio.com`.
- Public catalog nodes can be read with unauthenticated REST. `users/` cannot.
- Admin JSON (local only): `~/Development/Keystore/abherbs-backend-firebase-adminsdk-l5787-839f896846.json`.
- CLI: `firebase-tools` via nvm Node. Use `GOOGLE_APPLICATION_CREDENTIALS` pointing at the Admin JSON. `.firebaserc` selects `abherbs-backend`. Live rules snapshot: `firebase/database.rules.json`.
- Do not write production RTDB/Storage unless the user asked for a data change.
- Website Hosting deploy: `web/AGENTS.md` (only when asked).
- Play releases are option B: build a signed AAB here; the user uploads in Play Console.
- App Store Connect key `4AKYKM6RAW` may be used (Admin-level). Live iOS is 8.0.6. Do not upload a binary unless asked.

## Stores

- Android applicationId / iOS bundle id: `sk.ab.herbs`.
- Play: 1M+ installs. Local version may be ahead of the store.
- iOS metadata and an App Store Connect API key live under gitignored `ios/fastlane/`.

## Tests

There is no real test suite. After behavior changes, reason about filter navigation, plant detail translation fallback, IAP gates, and observation upload. Do not claim store or device verification you did not run.
