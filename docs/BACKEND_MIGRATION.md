# Java backend → Python (abherbs-auto)

Destination is `~/PycharmProjects/abherbs-auto`, not a new repo. The Flutter app keeps reading the same Firebase nodes.

**Status:** Index rebuild lives in `abherbs-auto` (`catalog_indexes.py` / `refresh_indexes.py`). Local JSON only: no Admin SDK, no Firebase write path. A promote step is not written yet.

The old Java `backend/` at `~/WebstormProjects/abherbs` is **off-project**. Leave that tree on disk for reference. Do not run it, change it, or treat it as a sibling.

## What actually has to move

| Java class | Keep? | Why |
|---|---|---|
| `Refresher` | **Yes — first** | Only remaining unique job. Rebuilds `counts_new`, `lists_new`, `search_new`, `search_photo_new` from headers + translations + APG IV. |
| `Localizer` | Later | Pushes Flutter `lib/l10n/intl_*.arb` (and `web/`) into `translations_app`. Still useful after UI-string edits. |
| `Namer` | Optional | One-off Wikidata/Wikispecies writes into `translations_taxonomy`. Do when a taxon needs names, not as a pipeline. |
| `Checker` | Absorb | Fold useful checks into existing `integrity_check.py`. Do not port the Windows `txt/*_missing.txt` writers. |
| `Creater` | **No** | Superseded by `add_plant.py` (Wikidata + POWO + header + synonyms + translations). |
| `Updater` | **No** | Sequential `plants_v2/{name}/id` from `plants.csv`. `add_plant.py` already uses `plants_to_update/count` as the next id. |
| `Firebase` / `FamilyIcons` / `Preparer` / `Converter` | **No** | One-off downloads and Wikispecies helpers. |

Python already owns ingest (`add_plant`, `upload_plant`, `process_plant`), rename, synonyms, observation review, FCM, and GCS. The gap is the **index rebuild**.

## Contract the port must not change

The shipping identifier is the 4-step filter. Do not “improve” keys, vocab, or list encoding.

- Filter key: `color_habitat_petal_distribution` with **empty slots allowed** (same as `lib/filter/filter_utils.dart` `getFilterKey`).
- Vocab (must match `Refresher.java`, not Checker):
  - color: `1`–`5` (white, yellow, red, blue, green)
  - habitat: `1`–`6` (meadow, garden, wetland, forest, rock, tree)
  - petal: `1`–`4` (≤4, 5, many, zygomorphic)
  - distribution: TDWG level-2 codes `10`–`14`, `20`–`29`, `30`–`38`, `40`–`43`, `50`–`51`, `60`–`63`, `70`–`79`, `80`–`85`, `90`–`91`
- Cartesian size including empty: `6 × 7 × 5 × 53 = 11,130` keys. That is why live `counts_4_v2` has 11,130 children.
- A plant matches a key when **every non-empty slot** is in the header’s list for that axis. Multi-value headers (several colors) match every selected value.
- Plant id in lists is the **index in `plants_to_update/list`**, which must equal `plants_headers/{id}` and `plants_v2/{name}/id`.
- List encoding is a map `{ "<id>": 1 }`, not a JSON array. Firebase drops empty maps, so live `lists_4_v2` has fewer keys (9,731) than counts.
- Writes from the refresher go only to staging: `counts_new`, `lists_new`, `search_new`, `search_photo_new`.
- The app reads `counts_4_v2`, `lists_4_v2`, `search_v3`, `search_photo`. Promote is a separate, explicit step, then bump `versions/db_update` so offline caches refresh.

Search index (`search_new/{lang}/{normalizedName}`):

- Languages in Java today: `bg cs da de en es et fi fr hr hu it ja ko lt lv nl no pl pt ro ru sk sl sr sv uk zh` plus `la`.
- From `translations/{lang}`: `label` (set `is_label: true`) and `names[]`, lowercased.
- Skip or log keys that are empty or contain `. / # $ [ ]` (illegal Firebase path chars).
- Latin (`la`): `plants_v2` name + synonyms; skip synonym strings that contain `.`.
- Value shape: `{ is_label?: true, list: { "<id>": 1 } }`.

Photo index (`search_photo_new`):

- Walk `APG IV_v3`. For Ordo / Familia / Subfamilia / Tribus / Subtribus / Genus / Subgenus / Sectio / Subsectio / Serie / Subserie: `{count, path}` under `taxon.lower()`.
- Freebase ids live under a sibling `m/{idWithoutSlashPrefix}`.
- Every catalog name: `name.lower()` → `{ count: 1, path: LatinName }`.
- Plant Freebase ids into `m/`. Synonyms only if that lowercased key is not already taken.
- The app looks up `search_photo/{scientific_name.lower().replace('.', '')}`.

## Suggested Python scripts

Keep the existing flat style in `abherbs-auto` (Firebase Admin, `constants.py`).

| Script | Job |
|---|---|
| `catalog_indexes.py` | Pure rebuild: filter keys, counts/lists, `search_new/{lang}`, `search_photo_new`. |
| `refresh_indexes.py` | CLI. `--input-dir` dump → `--output-dir` JSON. `--only counts|search|photo`. No Firebase. |
| `test_catalog_indexes.py` | Vocab size (11,130), match rules, search/photo shapes, CLI writes disk only. |
| `promote_indexes.py` | Not written. Will copy `counts_new`→`counts_4_v2`, `lists_new`→`lists_4_v2`, `search_new`→`search_v3`, `search_photo_new`→`search_photo`. Default `--dry-run`. Then set `versions/db_update`. |
| `localize_app.py` | Later. Read this repo’s `lib/l10n/intl_*.arb` → `translations_app`. |
| `integrity_check.py` | Add header range checks (color 1–5, habitat 1–6, petal 1–4, known TDWG) and id/`plants_to_update` alignment. |

Do not add a web framework, queue, or extra state library. These stay CLI tools you run after ingest.

Local run (no Firebase):

```
cd ~/PycharmProjects/abherbs-auto
python3 -m unittest test_catalog_indexes.py
python3 refresh_indexes.py --input-dir /path/to/dump --output-dir ./index_out
```

Dump files: `plants_to_update.json`, `plants_headers.json`, `plants_v2.json`, `apg_iv_v3.json`, and either `translations.json` or `translations/{lang}.json`. Output: `counts_new.json`, `lists_new.json`, `search_new/{lang}.json`, `search_photo_new.json`, `summary.json`.

Implementation notes (safe optimizations, same output):

- One `plants_headers` download and one `plants_to_update/list` download, not 1,413 Retrofit GETs.
- One `translations/{lang}` download per language; one `plants_v2` (or name+synonyms+freebase) download for Latin/photo.
- Still write **all 11,130 count keys** (including zeros) so a Python run can be diffed against live `counts_4_v2`.
- Omit empty list maps (Firebase would drop them anyway).

## Phases

1. **Port `Refresher` only.** Done as local JSON (`refresh_indexes.py`).
2. **Diff against live indexes** (read-only): Python output vs `counts_4_v2` / `lists_4_v2` / `search_v3` / `search_photo` on an unchanged catalog. Spot-check a few filter keys the app uses (empty, one axis, all four) and one Plant.id name in `search_photo`.
3. **Promote once**, by hand or `promote_indexes.py`, after the diff is clean. Bump `versions/db_update`.
4. **Hook ingest.** After `add_plant` / `rename_plant`, remind or call refresh (still staging). Do not auto-promote.
5. **Port `Localizer`** when you next change UI strings that the website/app remote copy must see.
6. **Fold Checker-style range checks** into `integrity_check.py`.

Do not promote on the first Python write.

## What this is not

- Not a rewrite of the 4-step identifier.
- Not a new encyclopedia query model. `lists_4_v2` stays until the client has something else to read.
- Not a merge of `abherbs-auto` into the Flutter repo.
- Not a live RTDB write until you ask for a refresh or a promote.

## After a plant is added (target workflow)

```
process_plant / add_plant / upload_plant
        ↓
refresh_indexes.py          → counts_new, lists_new, search_new, search_photo_new
        ↓
diff / sanity checks
        ↓
promote_indexes.py          → live nodes + versions/db_update
```

Until `promote_indexes.py` exists, refresh output stays on disk.
