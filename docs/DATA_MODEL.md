# Data model

Source of truth is **Firebase Realtime Database** `abherbs-backend`. Photos are **public objects** in GCS bucket `abherbs-resources`.

Most catalog trees are world-readable (the website fetches them with unauthenticated REST). Live rules are snapshotted in `firebase/database.rules.json` (phase 1, deployed 2026-08-13). Storage rules live in `firebase/storage.abherbs-resources.rules` and `firebase/storage.default.rules`. The next tightening is `firebase/database.rules.target.json` (needs a publish/credits backend). Do not deploy rule changes without an explicit ask.

### Access (phase 1)

| Path | Unauthenticated | Signed-in client |
|---|---|---|
| Catalog (`plants_v2`, `lists_4_v2`, `counts_4_v2`, `search_v3`, `search_photo`, `translations`, `translations_taxonomy`, `web`, …) | read | read |
| Staging indexes (`*_new` except volunteer queues) | read | read |
| `translations_new/{lang}/{plant}` | read; write one plant/field (8k cap). Root wipe denied. | same |
| `translations_app_new/{app}/{key}` | same pattern as `translations_new` | same |
| `users/{uid}` | denied | owner read. Client may write `token`, `favorites`, `purchases`, `credits` (0–10000). Not `old version` or `lifetime subscription`. |
| `users_photo_search/{lang}/{uid}` | denied | owner read/write |
| `credits/{uid}` | denied | owner read/write (string log, 64 chars) |
| `observations/by users/{uid}` | denied | owner read/write |
| `observations/public` | read | create/update own id (`{uid}_…`) only while `status == review`. Cannot change or delete a row already `public`. `stats` is Admin-only. |
| `observations/logs/{uid}` | denied | owner read/write |

Admin SDK bypasses these rules (ingest, observation reviewer).

The app still writes Google Translate output to `translations/{lang}-GT`; that persist now fails (in-session translate still works). Signed-out photo-search logs under `anonymous` also fail.

## Root nodes

| Path | Role |
|---|---|
| `plants_v2/{latinName}` | Full species record |
| `plants_headers/{id}` | Compact card used by lists |
| `lists_4_v2/{filterKey}` | Plant ids matching a filter combination |
| `counts_4_v2/{filterKey}` | Integer count for that combination |
| `search_v3/{lang}` | Name search index (`la` = Latin) |
| `search_photo/{normalizedName}` | Maps Plant.id scientific name → in-catalog path |
| `APG IV_v3` | Taxonomy tree for browse/search |
| `translations/{lang}/{latinName}` | Human (or Wikidata) plant text |
| `translations/{lang}-GT/{latinName}` | Google Translate cache |
| `translations_new/{lang}/{latinName}` | Volunteer edits from app or website |
| `translations_taxonomy/{lang}/{taxon}` | Localized taxon names |
| `synonyms/{latinName}` | IPNI synonym list |
| `lists_custom` | Editorial lists ("new", "by language", dated drops) |
| `plants_to_update` | `{count, list[]}` of Latin names in the live catalog |
| `families_to_update` | Same idea for family illustration packs |
| `versions` | Store version codes + `db_update` |
| `settings` | `ai_engine`, generic Plant.id labels to ignore |
| `promotions` | Time-boxed free unlocks |
| `users/{uid}` | Profile flags, favorites, credits, token |
| `users_photo_search/{lang}/{uid}/{ts}` | Logged Plant.id results |
| `observations/by users/{uid}` | Private observations |
| `observations/public` | Shared observations (subscription) |
| `observations/logs` | Review / publish log |
| `credits` | Credit spend/earn log |
| `web/{lang}` | Legacy About/Help and old-site chrome. The current website does not read this; chrome lives in `web/src/locales.json`. |
| `web/catalog/{id}` | Slim website plant row (`id`, `name`, `family`, `url`, `illustrationUrl`). Written with each incremental add. |
| `web/labels/{lang}/{id}` | Sourced vernacular for that plant, or omitted. Not inverted from `search_v3`. |

Live sizes (public REST, 2026-03-26):

- `plants_headers`: 1,413
- `plants_v2`: 1,419
- `plants_to_update/count`: 1,413
- `lists_4_v2`: 9,731 keys
- `counts_4_v2`: 11,130 keys
- `search_photo`: 8,529 name mappings

## Species record (`plants_v2`)

Keyed by Latin binomial, e.g. `plants_v2/Acer campestre`.

```json
{
  "id": 0,
  "name": "Acer campestre",
  "author": "L.",
  "floweringFrom": 5,
  "floweringTo": 6,
  "heightFrom": 300,
  "heightTo": 2000,
  "toxicityClass": 0,
  "illustrationUrl": "Sapindales/Sapindaceae/Acer_campestre/Acer_campestre.webp",
  "photoUrls": ["Sapindales/Sapindaceae/Acer_campestre/ac1.webp", "..."],
  "videoUrls": [],
  "sourceUrls": ["..."],
  "ipniId": "781250-1",
  "gbifId": 3189863,
  "usdaId": "ACCA5",
  "freebaseId": "/m/028j7f",
  "wikiName": "Acer campestre",
  "wikilinks": {
    "data": "https://www.wikidata.org/wiki/Q157810",
    "commons": "...",
    "species": "..."
  },
  "APGIV": {
    "00_Genus": "Acer",
    "02_Familia": "Sapindaceae",
    "03_Ordo": "Sapindales",
    "11_Superregnum": "Eukaryota"
  }
}
```

`lib/entity/plant.dart` also mentions `synonyms` and `videoUrls` on the client object; synonyms in production live mainly under `synonyms/{name}/ipni`.

**Identity problem:** the primary key is the display name. `rename_plant.py` must copy `plants_v2`, `synonyms`, and every `translations/{lang}` child.

## Header (`plants_headers/{id}`)

```json
{
  "name": "Acer campestre",
  "family": "Sapindaceae",
  "url": "Sapindales/Sapindaceae/Acer_campestre/ac1.webp",
  "filterColor": [5, 2],
  "filterHabitat": [6],
  "filterPetal": [2],
  "filterDistribution": [10, 11, 12, 13, 14, 33, 34, 20, 72, 75, 76]
}
```

A plant can belong to **multiple** values of one filter (green *and* yellow). Ingest writes the union; list generation fans the plant into every combination.

The Flutter app keeps reading this node, including the filter arrays. The public website does **not** use those filters. It reads `web/catalog` (explicit `id` + `illustrationUrl`) and `web/labels/{lang}` once the catalog covers `plants_to_update/count`. Until a full rebuild has been published, the site falls back to `plants_headers` plus per-card `translations` / `plants_v2` fetches.

Rebuild locally with `refresh_indexes.py --only web` (`web_catalog_new.json`, `web_labels_new/`). That does not write Firebase.

## Website catalog (`web/catalog/{id}`)

```json
{
  "id": 0,
  "name": "Acer campestre",
  "family": "Sapindaceae",
  "url": "Sapindales/Sapindaceae/Acer_campestre/ac1.webp",
  "illustrationUrl": "Sapindales/Sapindaceae/Acer_campestre/Acer_campestre.webp"
}
```

`id` is the `plants_to_update` list index (same as `plants_headers/{id}` and search). `illustrationUrl` is copied from `plants_v2`. Do not invent it from `url` at publish time except as a fallback when `plants_v2` has none. Labels live next door:

```json
"web/labels/en/0": "common maple"
```

Empty / missing means show the Latin name. Later-language publishes (`publish_new_plant_translations.py` and the same helper) must write `web/labels/{lang}/{id}` when they set a sourced `label`.

## Filter vocabulary

Order in a key is always `color_habitat_petal_distribution`. Empty slot = not selected. Example: `1_1_1_` = white + meadow + 4 petals + any region.

| Attribute | Codes |
|---|---|
| Color | 1 white, 2 yellow, 3 red, 4 blue, 5 green |
| Habitat | 1 meadow, 2 garden, 3 wetland, 4 forest, 5 rock, 6 tree |
| Petal | 1 four, 2 five, 3 many, 4 zygomorphic |
| Distribution | TDWG level-2 numeric codes (10 Northern Europe … 91 Antarctic). Mapped from POWO distribution text via `abherbs-auto/tdwg.csv`. |

Client: `lib/filter/filter_utils.dart`.

## Translations

`translations/{lang}/{latinName}`:

| Field | Meaning |
|---|---|
| `label` | Common name from a source in that language (Wikidata label/alias, that Wikipedia title, EPPO Global Database, or a flora). Never a translation of the English name. If no source, omit; the app shows the Latin name. |
| `names` | Extra sourced common names |
| `wikipedia` | Language Wikipedia URL |
| `description`, `flower`, `inflorescence`, `fruit`, `leaf`, `stem`, `habitat` | Required for "fully translated" |
| `toxicity`, `herbalism`, `trivia` | Optional |
| `sourceUrls` | Localized sources |

Wikidata ingest creates a huge set of language codes (Wikipedia sitelinks). The app only *requests* the device / preferred language, with GT fallback.

`isTranslated()` in `plant_translation.dart` requires the seven body fields above. Until they exist, the client may call Translate. Caching under `{lang}-GT` is Admin-only now; the official UI still shows the in-memory result for that session.

Volunteer improvements go to `translations_new` (app long-press or the website PATCH). Live `translations` is read-only for clients.

## Observations

```
observations/
  by users/{uid}/
    by date/list/{key}     Observation
    by plant/{plant}/...
  public/
    by date/list/{key}
    by plant/...
    stats                  aggregates
  logs/
```

Observation fields (`lib/entity/observation.dart`): `id`, `plant`, `date` (legacy Java-style map + `time` millis), `latitude`, `longitude`, `note`, `photoPaths`, `status` (`private` / `public`), `order` (negative timestamp for newest-first), `indoors`.

`id` is `{uid}_{millis}`. Private rows are owner-only. Publish writes the same payload to `observations/public` with `status: review`; the reviewer (`review_observations.py`) sets `public` or `rejected` via Admin SDK.

Upload statuses used when publishing: `private`, `review`, `public`, `success`, `rejected`, `failure`.

`abherbs-auto/review_observations.py` is a Tkinter reviewer: download photos from the bucket, accept / reject / skip.

Public stats at last read: 1,509 observations, 49 observers, 572 species, heaviest countries SK / SI / GB / US. `lastDate` is 2022-09-24 — the public feed looks quiet.

## Users

Read by the app after sign-in (`lib/signin/authentication.dart`). Client-writable fields are only `token`, `favorites/{plantId}`, `purchases`, and `credits` (number 0–10000).

- `old version` — former plus-app entitlement (Admin / existing value only)
- `lifetime subscription` — same
- `credits` — rewarded-ad balance (client can still set its own number)
- `token` — FCM
- `purchases` — product id list (not used as the IAP gate)
- `favorites/{plantId}`

## Photo storage layout

```
gs://abherbs-resources/
  photos/{Order}/{Family}/{Genus_species}/
    ac1.webp                square 512
    .thumbnails/ac1.webp    128
    Acer_campestre.webp     illustration
  families/
  observations/{uid}/{Plant_name}/{file}.jpg
  misc/                     terms, privacy
```

Firebase Storage: `photos/`, `families/`, `offline/`, `misc/` are public-read, client-write denied. `observations/{uid}/**` write is that uid only (image, 10 MB). The default bucket `abherbs-backend.appspot.com` is deny-all. Public **listing** of the GCS bucket is IAM, not these rules.

Local staging on this machine (from `abherbs-auto/constants.py`):

- Source plants: `~/whatsthatflower/plants/{Family}/{Name}/`
- Prepared photos: `~/whatsthatflower/storage/photos/{Order}/{Family}/{Genus_species}/`
- Observation review: `~/whatsthatflower/observations/`
- WCVP cache: `~/whatsthatflower/wcvp/`

Photo file names are `{first letter of genus}{first letter of species}{n}.webp` (`ac1.webp` for *Acer campestre*).

## Search by photo

1. Client posts the image to Plant.id v2.
2. Each suggestion's scientific name is looked up in `search_photo/{lowercase name without dots}`.
3. A hit contains `count` + `path` into the catalog (species or higher taxon).
4. Results are logged under `users_photo_search/{lang}/{uid}/{ts}` when the user is signed in. Anonymous logs are denied.

`settings/generic_entities` / `generic_labels` list Plant.id labels that are too generic to treat as a species (`plant`, `flower`, `leaf`, …).

## How lists and counts are rebuilt

The 4-axis indexes are not maintained by the Flutter app. After plants or headers change, `abherbs-auto/refresh_indexes.py` rebuilds them locally:

1. Generates every combination of color × habitat × petal × TDWG region (including empty “not selected”).
2. For each plant header, increments `counts_new/{key}` and adds the numeric plant id to `lists_new/{key}` when all selected slots match (a plant with several colors matches every one of those color slots).
3. Rebuilds `search_new/{lang}` from `translations/{lang}` labels and extra names, plus Latin + synonyms under `la`.
4. Rebuilds `search_photo_new` from APG IV taxa, Latin names, Freebase ids, and synonyms.

Those `*_new` trees are staging and client-write denied (Admin SDK only). The app reads `counts_4_v2`, `lists_4_v2`, `search_v3`, `search_photo`. Promote by copying staging → live, then set `versions/db_update`. See [BACKEND_MIGRATION.md](BACKEND_MIGRATION.md). The script currently writes JSON on disk only; it does not write Firebase.

## Why this model will need to change

Filter lists are **precomputed Cartesian products**. That is fast on a phone for 1.4k plants and four tiny enums. It is the wrong index for:

- 10⁵–10⁶ taxa
- plants that do not have petals or a flower color
- queries like "trees of Slovakia" or "Fabaceae in Mexico"

Any encyclopedia work should add a stable taxon id and a query model that is not `lists_4_v2`, without deleting the current indexes until the identifier UI is replaced.
