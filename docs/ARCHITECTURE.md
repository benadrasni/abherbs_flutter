# Architecture

## System

```
                    ┌─────────────────────────────┐
                    │   whatsthatflower.com       │
                    │   (abherbs-web, React 15)   │
                    │   public plant pages,       │
                    │   volunteer translations    │
                    └──────────────┬──────────────┘
                                   │ REST
                                   ▼
┌──────────────┐    SDK     ┌─────────────────────┐    Admin SDK
│ Flutter app  │◀──────────▶│ Firebase project    │◀──────────────┐
│ sk.ab.herbs  │            │ abherbs-backend     │               │
│ Android+iOS  │            │ RTDB + Auth + FCM   │               │
└──────┬───────┘            │ Remote Config       │               │
       │                    │ Crashlytics / GA    │               │
       │ HTTPS              └──────────┬──────────┘               │
       │                               │                          │
       ▼                               ▼                          │
 Plant.id API                 GCS bucket                          │
 Google Translate             abherbs-resources                   │
 Google Maps Static           photos / families /                 │
 AdMob / IAP                  observations / misc                 │
                                                              ┌───┴────────┐
                                                              │ abherbs-   │
                                                              │ auto       │
                                                              │ Python     │
                                                              └────────────┘
```

Firebase project number `319603655901`. Realtime Database URL `https://abherbs-backend.firebaseio.com`.

Two storage names appear in code:

- `abherbs-backend.appspot.com` — default Firebase Storage bucket (app config)
- `gs://abherbs-resources` — public photo/CDN bucket the UI actually loads (`storage.googleapis.com/abherbs-resources/`)

## Flutter client

Stateful Flutter app, Material, portrait-first. No separate state library. Screens talk to Firebase Realtime Database through `DatabaseReference` helpers in `lib/utils/utils.dart`.

### Startup (`lib/main.dart`)

1. `Firebase.initializeApp` + RTDB persistence (20 MB).
2. Crashlytics (off in debug).
3. Remote Config (ads frequency, IPNI/POWO URLs, help videos).
4. Shared preferences, ATT (iOS), AdMob, locale, saved filter, first filter route.
5. IAP purchase stream and FCM topic `notifications-{languageCode}`.

### Navigation

The first route is the first unused filter in `Preferences.myFilterAttributes` (default: color → habitat → petal → distribution). After the last filter, `PlantList` reads `lists_4_v2/{color}_{habitat}_{petal}_{region}`.

The drawer exposes the same filters plus enhancements, settings, legend, feedback, and (when purchased) search, observations, custom lists.

Deep links from FCM:

| `action` | Opens |
|---|---|
| `plant` | Species page by Latin name |
| `list` | `PlantList` on a DB path (used for "new plants" / "flowers with video") |
| `browse` | External URL |

Species pages are also shared as `https://whatsthatflower.com/?plant={Name}&lang={code}`.

### Plant page

Tabs in `lib/detail/`:

- Gallery (photos, illustration, optional YouTube)
- Info (names, height, flowering, sectioned text, sources)
- Taxonomy (APG IV path, IPNI synonyms, POWO link)
- Observations for that plant (paid)

Long-press on a text section opens `PlantDetailEdit`, which writes the volunteer improvement to `translations_new/{lang}/{plant}/{section}`.

Missing sections are filled at read time: local language → `{lang}-GT` cache → English (or Slovak when the UI language is Czech) → Google Translate API → write back to `{lang}-GT`.

### Monetization

Free core: 4-step filter, plant pages, ads.

One-time IAPs (`lib/purchase/purchases.dart`):

| Product | Android id | iOS id |
|---|---|---|
| Remove ads | `no_ads` | `NoAds` |
| Search by name / taxonomy | `search` | `search` |
| Custom filter order | `custom_filter` | `custom_filter` |
| Offline photos + DB sync | `offline` | `offline` |
| Observations | `observations` | `observations` |
| Search by photo | `search_by_photo` | `search_by_photo` |

Subscriptions (need Observations first): `store_photos_monthly`, `store_photos_yearly`. They unlock public observation sharing and cross-device photo storage.

Legacy users of the old paid app (`sk.ab.herbsplus`) get `users/{uid}/old version = true`, which unlocks the one-time features.

Photo search without the IAP spends a **credit**. Credits come from rewarded ads (`Auth.changeCredits`).

Promotions are date windows under `promotions/` (all currently expired).

There used to be two Play apps (free + plus). Only `sk.ab.herbs` is the current product; plus remains in `google-services.json` and in `versions/herbsplus`.

### Auth

Firebase Auth: email/password, Google, Apple, phone. Observations and photo search expect a signed-in user. Favorites, FCM token, purchase list, credits, and lifetime-subscription flag live under `users/{uid}`.

### Offline

Paid. `lib/settings/offline.dart` keeps selected RTDB subtrees synced and downloads family/plant WebP files from `abherbs-resources` into the app documents directory. Progress is compared to `plants_to_update/count` and `families_to_update`. `versions/db_update` is the last catalog refresh date (`2022-06-06` at last read — that field is stale relative to later plant adds).

### Internationalization

- UI: `lib/l10n/intl_*.arb` via `intl_utils` → `lib/generated/`.
- Country names: `data/*.json`.
- Plant content: Firebase `translations` / `translations_taxonomy`.

### External APIs

| Service | Where | Purpose |
|---|---|---|
| Plant.id v2 `api.plant.id/v2/identify` | `search_photo.dart` | Photo identification |
| Google Translate v2 | plant detail | On-demand body text |
| Google Maps Static | observations | Map thumbnails |
| POWO / IPNI | Remote Config + taxonomy | Species page links |
| AdMob (AppLovin + Facebook mediation on Android) | banners, interstitial, rewarded | Ads |

API keys live in gitignored `lib/keys.dart`.

### Notifications

FCM data payload + language topics. `abherbs-auto/send_notifications.py` translates title/body and sends per-language messages that open a plant or a custom list.

## Platforms

| | Android | iOS |
|---|---|---|
| Id | `sk.ab.herbs` | `sk.ab.herbs` |
| Store name | What's that flower? | What's that flower? |
| Min / target | minSdk 23, compile/target 35 | portrait iPhone, all iPad orientations |
| Signing | local keystore via `keystore.properties` | Xcode + fastlane App Store Connect key |
| Release tooling | Gradle / Play upload (manual today) | `ios/fastlane` `update_release_notes` |

GitHub remote: `https://github.com/benadrasni/abherbs_flutter`.
