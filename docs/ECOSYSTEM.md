# Ecosystem

Three local projects share one Firebase backend. They are grouped as **`~/whatsthatflower`** (`app`, `ingest`, `web` symlinks; remotes stay put).

```
~/whatsthatflower                     workspace (not a git repo)
~/whatsthatflower/app              →  ~/StudioProjects/abherbs_flutter
~/whatsthatflower/ingest           →  ~/PycharmProjects/abherbs-auto
~/whatsthatflower/web              →  ~/WebstormProjects/abherbs-web
~/whatsthatflower/plants              incoming plant folders + `_jobs/`
~/whatsthatflower/storage/photos      prepared WebP tree
~/whatsthatflower/observations        observation review downloads
~/whatsthatflower/wcvp                Kew WCVP zip + sqlite
~/Development/Keystore                Android keystore + Firebase admin JSON (secrets; not in the workspace)
```

Editor: `~/whatsthatflower/whatsthatflower.code-workspace`.

`~/WebstormProjects/abherbs` (old native Android apps + Java `backend/`) is left on disk for reference. It is **not** a sibling project. Do not change or run it. Index rebuild belongs in `abherbs-auto` ([BACKEND_MIGRATION.md](BACKEND_MIGRATION.md)).

## abherbs-auto

Python 3 scripts, Firebase Admin SDK, BeautifulSoup, Pillow, Tkinter. Credentials path is hardcoded in `constants.py` to the local admin JSON.

| Script | Job |
|---|---|
| `process_plant.py` | Tkinter UI: crop incoming photos to 512 / 128 WebP, then `add_plant` + `upload_plant` |
| `add_plant.py` | Write `plants_v2`, `plants_headers`, `synonyms`, `translations` from Wikidata + POWO |
| `upload_plant.py` | Upload a prepared folder to `abherbs-resources/photos/...` and make objects public |
| `plants_to_upload.txt` | Batch lines: `order;family;plant;wikidata;flowerFrom;flowerTo;hFrom;hTo;color;habitat;petal` |
| `add_synonyms.py` | Backfill IPNI id + author + synonym list |
| `rename_plant.py` | Copy plant + synonyms + translations to a new Latin key |
| `add_flower_with_video.py` | Append a plant id to every language's "Flowers with video" custom list |
| `catalog_indexes.py` / `refresh_indexes.py` | Rebuild counts/lists/search/photo JSON from a catalog dump. Does not write Firebase. |
| `integrity_check.py` | Missing English sections, empty taxonomy names, broken observations |
| `review_observations.py` | Tkinter accept / reject / skip for pending public photos |
| `observation_stats.py` | Recompute `observations/public/stats` (Nominatim for country) |
| `send_notifications.py` | Per-language FCM via `deep_translator` |
| `storage_upload_file.py` / `storage_make_public.py` | GCS helpers |
| `tdwg.csv` | TDWG geography used to turn POWO region names into filter codes |

Ingest sources:

- **Wikidata** entity JSON → labels, aliases, sitelinks, GBIF (`P846`), USDA (`P1772`), IPNI (`P961`), Freebase (`P646`)
- **Wikispecies** HTML → APG ranks (then order path from `constants.apgiv_values`)
- **POWO** (`plantsoftheworldonline.org`) → author, synonyms, native distribution
- Local `sources.txt` in the plant folder → `sourceUrls`

Known fragility: POWO HTML selectors and Wikidata property assumptions. Several IPNI ids are hardcoded overrides. `plantsoftheworldonline.org` is already an old hostname (POWO now lives at `powo.science.kew.org`; the app Remote Config already points there).

## abherbs-web

Create React App **0.9** / React **15** / Material UI **0.20**. Last-generation stack; it still works as a static public site.

Routes (`src/Main.js`):

| Path | Page |
|---|---|
| `/` | Random or `?plant=` species page + store badges |
| `/translate_flower` | Volunteer plant-text editor |
| `/translate_app` | Volunteer UI-string editor |
| `/help`, `/about` | Static copy from `web/{lang}` |

The homepage loads:

1. `plants_to_update/list.json` — catalog names
2. `plants_v2/{name}.json`
3. `translations/{lang}`, `{lang}-GT`, `en`

Shared plant URLs from the app land here. Website copy for ~34 languages is stored in Firebase `web/`, not in the React repo.

## Other product surfaces

- Support inbox: `support@whatsthatflower.com`
- Developer Play listing: Benko, Adrian
- Legacy paid package `sk.ab.herbsplus` (no longer the shipping app)
- Legal HTML in `abherbs-resources/misc/`

## Related third parties

| Party | Used for |
|---|---|
| Wikidata / Wikipedia / Commons / Wikispecies | Names, links, taxonomy hints |
| POWO / IPNI / Kew | Accepted name, synonyms, distribution, species URL |
| GBIF, USDA PLANTS | Crosswalk ids |
| Plant.id | Photo identification |
| Google Translate | On-read and notification translation |
| Google Maps | Observation maps |
| AdMob + mediation | Ads |
| Play Billing / StoreKit | IAP + subscriptions |
