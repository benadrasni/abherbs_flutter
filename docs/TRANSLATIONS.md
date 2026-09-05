# Translations — retire Google Translate

Long-term goal: **every supported UI language has real plant text in the catalog**, so the app and website never call Google Translate and Firebase no longer stores `translations/{lang}-GT`.

This sits beside the encyclopedia vision. The identifier stays; the on-read machine translation goes.

Do not start a full-catalog language pass, write Firebase, or ship a client that drops the Translate API until that language (or the whole set) is actually complete. This file is the plan.

## What “supported languages” means

The **app UI languages** in `lib/l10n/intl_*.arb` / `lib/settings/setting_utils.dart`. Content keys are the Firebase language codes (`nb` → `no`; `zh_TW` → `zh`):

`ar bg cs da de en es et fa fi fr he hi hr hu id it ja ko lt lv no nl pl pt ro ru sk sl sr sv uk zh`

That is 33 catalog languages (35 ARB files: `en`, `en_US`, `en_UK` share `en`).

Not in scope for full body text:

- The hundreds of Wikidata sitelink codes under `translations/` (labels and Wikipedia URLs only).
- `*-GT` trees. Those are a cache to delete, not a source to promote.

UI chrome is already translated: ARB files, `web/src/locales.json`, `data/*.json` country names. The gap is **species body text**.

Name search (`search_v3`) currently indexes a slightly smaller set (no `ar fa he hi id`). Filling body text does not by itself add those search trees.

## What exists today (backup 2026-08-20)

A plant is “fully translated” when the seven identification fields exist: `description`, `flower`, `inflorescence`, `fruit`, `leaf`, `stem`, `habitat`. Optional: `toxicity`, `herbalism`, `trivia`.

| Language | Official full-7 | Typical content | `{lang}-GT` full-7 |
|---|---|---|---|
| `en` | 1,421 | Source of truth | none |
| `sk` | 1,421 | Editorial, from sourced English | 13 |
| `de` | 1,068 | Partial editorial | 351 |
| `fr` | 497 | Partial editorial | 725 |
| `es` `it` `pl` `ru` `cs` | tens to low hundreds | Mostly labels | hundreds–1,200 |
| Other UI languages | ~0–20 | Wikidata `label` / `names` / `wikipedia` | ~400–1,375 |

Almost every non-English, non-Slovak reader who opens a species page is reading Google Translate of English (Czech: of Slovak), either from `{lang}-GT` or live from the Translate API. Client writes to `{lang}-GT` now fail the rules; in-session translate still works. Offline still `keepSynced`s the GT tree. The website still fetches `{lang}-GT`.

Other Google Translate call sites:

| Surface | Where |
|---|---|
| Plant body on read | `app/lib/detail/plant_detail.dart` |
| Offline DB sync | `app/lib/settings/offline.dart` |
| Website plant page | `web/src/api.js` `loadPlantText` |
| FCM title/body | `ingest/scripts/send_notifications.py` (`deep_translator.GoogleTranslator`) |
| “Flowers with video” list titles | `ingest/scripts/add_flower_with_video.py` |

Taxonomy names (`translations_taxonomy`) are Wikidata, not GT. They stay sourced. Missing taxon labels fall back to Latin; that is not a Translate-API problem.

## Rules that do not change

1. **Never translate an English common name.** `label` and `names` only from a source in that language (Wikidata label/alias, that Wikipedia title, EPPO, or a flora). If none, omit `label`; the UI shows Latin.
2. **Do not invent facts.** Body text is the curated English seven fields, rewritten in the target language. Prefer a page in that language when it actually covers the plant (`translations/{lang}/sourceUrls` = pages used, not a copy of English URLs).
3. **Do not copy `{lang}-GT` into `translations/{lang}`.** GT is what we are removing. Volunteer `translations_new` may be reviewed in; the GT cache may not.
4. **English remains the identification source.** `/update-plant` rewrites English first. Other languages follow that English (and any language-specific flora), they do not drift on old wording.
5. **Live identifier and filters stay untouched.**

Slovak today is the template: sourced vernaculars, then the same seven fields written in Slovak from those facts. Long-term every UI language gets that treatment.

## Target state

For each UI language `L` and each catalog plant:

- `translations/L/{latin}` has the seven body fields (and optional `toxicity` / `herbalism` / `trivia` when English has them).
- `label` / `names` only if sourced; otherwise omitted.
- `isTranslated()` is true, so the client never reaches the GT branch.
- `translations/L-GT` does not exist.
- App, website, offline, and notification scripts have no Translate API / `GoogleTranslator` dependency.

Volunteer edit (`translations_new`, `/translate_flower`) can stay. It improves official text; it is not a substitute for finishing the catalog.

## Why not “just translate on ingest with Google”?

That would keep Google in the product, freeze GT quality into the official tree, and go stale the next time English is rewritten. The point of this goal is **owned text in `translations/{lang}`**, then **no Google Translate anywhere**.

## Work that has to stay in lockstep

When English seven fields change, every language that already has body text for that plant is stale until rewritten. Today GT of the new English is “fresh” only if the `{lang}-GT` row is missing or manually cleared; the cache is not invalidated. The new pipeline must:

- Treat English (plus `plants_v2.inflorescenceType`) as the revision that other languages track.
- Re-translate / rewrite a plant in all complete languages as part of `/update-plant` and `/add-plant`, not as a later optional pass.
- Until a language is complete, the app may still GT that language. After it is complete, missing a plant is a catalog bug, not a Translate call.

New species: do not add English-only body and rely on GT. Same packet writes every UI language (or the subset already on the “no GT” list) before incremental publish.

## Phases (not a schedule)

### 1. Measure and keep measuring

Coverage table: per UI language, count of plants with full seven fields vs catalog size (`plants_to_update/count`). Optional fields and sourced `label` rates separately. Re-run after each language batch. The 2026-08-20 backup numbers above are the baseline.

### 2. Finish languages one at a time

Do not interleave 33 incomplete languages. Order by how close official text already is, then by how many people hit GT:

1. `de` (already ~1,068 / 1,413)
2. `fr`
3. `cs` (today GT-from-Slovak; deserves real Czech)
4. High-use remainder: `pl ru es it ja nl pt uk` …
5. The rest of the UI set

For each language:

- Source vernaculars (already mostly present from Wikidata).
- Write the seven fields (and optionals when English has them) into `translations/{lang}`, with `sourceUrls` for that language.
- Rebuild `search_v3/{lang}` if labels changed.
- Write `web/labels/{lang}/{id}` only when `label` is sourced.
- Do **not** delete `{lang}-GT` until that language is complete for the whole catalog. Incomplete official text plus leftover GT is how the client works today (`isTranslated()` short-circuits). Partial official + leftover GT for the same plant is OK: official fields win via merge.

A language is **complete** when every `plants_to_update` name has the seven fields in `translations/{lang}`. Then:

- Stop calling Translate for that language in the app and website (fallback is English/Slovak only if a row is missing — treat as a bug).
- Delete `translations/{lang}-GT`.
- Offline: stop `keepSynced` of that GT child.

### 3. Take Google out of the client and site

Only after **all** UI languages are complete:

- Remove the Translate HTTP call, `translateAPIKey` use, `languageGTSuffix`, `entity/translations.dart`, and the GT branch in `plant_detail.dart`.
- Fallback if a row is incomplete: English (Czech → Slovak, as now) **without** translating it. Show Latin for a missing `label`.
- Website `loadPlantText`: drop the `{lang}-GT` fetch.
- Offline: sync only `translations/{lang}` (+ English if you still want it as emergency fallback).
- Ingest: replace `GoogleTranslator` in `send_notifications.py` and `add_flower_with_video.py` with stored strings (ARB / a small notification table / already-translated plant `label`).
- Delete remaining `translations/*-GT` nodes (including non-UI languages such as `el-GT`, `tr-GT`).
- Rules: no special case for GT writes (already denied).

Ship that client only when the catalog side is done. An app that cannot GT and a language that is not full-7 is a blank species page.

### 4. Keep it done

- `/add-plant` and `/update-plant` write every UI language in the same publish as English.
- Coverage check in ingest (`integrity_check` or similar): catalog plant × UI language × seven fields.
- Volunteers still patch via `translations_new`.

## Scale

~1,413 plants × 31 non-English, non-Slovak UI languages × 7 fields ≈ **300k paragraphs**, plus optionals and later English rewrites. That is a pipeline, not a one-session edit. German first cuts the largest remaining official gap.

Wikidata label coverage is already good for most of these languages; the work is body text.

## Out of scope until asked

- Translating UI ARB strings (already present).
- Machine-translating taxonomy (`translations_taxonomy` stays sourced).
- Filling Wikidata-only languages (hundreds of codes) with body text.
- Changing filter indexes or English source rules.
- Promoting `translations_new` in bulk without review.
- Deploying rule or catalog writes.

## Related files

- Client: `lib/detail/plant_detail.dart`, `lib/entity/plant_translation.dart`, `lib/settings/offline.dart`, `lib/utils/utils.dart`
- Website: `web/src/api.js`
- Ingest: `scripts/send_notifications.py`, `scripts/add_flower_with_video.py`, `catalog/web_catalog.py` (already skips `*-GT`)
- Data: `translations/{lang}`, `translations/{lang}-GT`, `translations_new`, `translations_taxonomy`, `search_v3/{lang}`, `web/labels/{lang}`
