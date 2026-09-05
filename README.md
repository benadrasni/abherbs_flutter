# What's that flower?

A hobby project with a long horizon: a comprehensive plant encyclopedia, starting from a shipping flower-identification app.

The live product is **What's that flower?** (`sk.ab.herbs`).

- [Google Play](https://play.google.com/store/apps/details?id=sk.ab.herbs) — 1M+ installs
- [App Store](https://apps.apple.com/us/app/whats-that-flower/id1449982118)
- [whatsthatflower.com](https://whatsthatflower.com/)

This repository is the Flutter client. Plant data lives in Firebase. The three live projects open together as **`~/whatsthatflower`**:

| Project | Path | Workspace link |
|---|---|---|
| Flutter app | `~/StudioProjects/abherbs_flutter` | `~/whatsthatflower/app` |
| Data tools | `~/PycharmProjects/abherbs-auto` | `~/whatsthatflower/ingest` |
| Website | `~/WebstormProjects/abherbs-web` | `~/whatsthatflower/web` |

```bash
open ~/whatsthatflower/whatsthatflower.code-workspace
```

## Current snapshot (2026-03-26)

| Item | Value |
|---|---|
| App version in this repo | `8.0.7+807` (Play/App Store last seen as `8.0.6`) |
| Plants in catalog | **1,413** headers (`plants_to_update/count`) |
| Records in `plants_v2` | 1,419 (a few leftover / renamed keys) |
| Public observations | 1,509 from 49 observers, 572 species |
| App UI languages | 35 `.arb` files |
| Firebase project | `abherbs-backend` |
| Photo bucket | `gs://abherbs-resources` |

The catalog is flower-first (color, habitat, petal shape, TDWG region). That is a strong identifier, not yet an encyclopedia of all plants.

## How the app works

1. The user answers a short filter: flower color, habitat, petal type, then world region.
2. Each answer is looked up in precomputed Realtime Database indexes (`counts_4_v2`, `lists_4_v2`).
3. The resulting plant list opens; a tap loads the species page (photos, description, taxonomy, observations).
4. Paid add-ons unlock name/taxonomy search, photo ID (Plant.id), offline photos, custom filter order, and field observations.

More detail: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md), [docs/DATA_MODEL.md](docs/DATA_MODEL.md), [docs/VISION.md](docs/VISION.md). Retiring Google Translate: [docs/TRANSLATIONS.md](docs/TRANSLATIONS.md).

## Repository layout

```
lib/
  main.dart                 app start, IAP, FCM, locale
  filter/                   color / habitat / petal / distribution
  detail/                   plant page (gallery, info, taxonomy, edit)
  search/                   name, taxonomy, photo
  observations/             private + public field notes
  purchase/                 IAP + photo-storage subscriptions
  signin/                   email, Google, Apple, phone
  settings/                 language, region, offline, filter order
  entity/                   Plant, Observation, translations
  l10n/                     UI strings (intl_utils)
android/                    applicationId sk.ab.herbs
ios/                        bundle id sk.ab.herbs, fastlane metadata
data/                       localized country names
res/images/                 filter icons and placeholders
docs/                       project documentation
```

## Run locally

```bash
cd ~/StudioProjects/abherbs_flutter
flutter pub get
flutter run
```

Secrets are gitignored and expected on this machine:

- `lib/keys.dart` — Translate, Maps, Plant.id, AdMob unit IDs
- `lib/firebase_options.dart` — FlutterFire options
- `android/app/google-services.json`, `android/keystore.properties`
- `ios/Runner/GoogleService-Info.plist`, `ios/fastlane/`

## Documentation

- [Vision](docs/VISION.md) — encyclopedia goal vs what ships today
- [Architecture](docs/ARCHITECTURE.md) — client, monetization, APIs
- [Data model](docs/DATA_MODEL.md) — Firebase + Storage
- [Ecosystem](docs/ECOSYSTEM.md) — Python tools and website
- [Access](docs/ACCESS.md) — Play Store, App Store, Firebase (current decisions)
- [AGENTS.md](AGENTS.md) — notes for future coding sessions

## Support

- Product: [support@whatsthatflower.com](mailto:support@whatsthatflower.com)
- Privacy / terms: hosted under `storage.googleapis.com/abherbs-resources/misc/`
