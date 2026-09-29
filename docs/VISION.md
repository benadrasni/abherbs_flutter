# Vision

## Destination

A comprehensive encyclopedia-like application for **all plants in the world**: species pages that a person can trust, find, and contribute to, on a phone, **in every language the app already supports**.

The shipping product is already a real step toward that: a multilingual flower identifier with curated photos, botanical text, APG IV taxonomy, synonyms, and user observations. It is not yet an encyclopedia of plants. It is a **flower identification key** with a few thousand carefully prepared angiosperms. Missing species body text falls back to English. Vernacular names stay in the language that has them. The Translate API and the `{lang}-GT` cache are gone. Official body text in every UI language is still the goal. Plan: [TRANSLATIONS.md](TRANSLATIONS.md).

## What exists today

- **1,413** curated flowering plants, each with photos, filter attributes, and a species page.
- Identification by **four human-visible traits**: color, habitat, petal type, TDWG level-2 region.
- Species pages with height, flowering months, toxicity class, APG IV path, IPNI / GBIF / USDA / Wikidata links, and sectioned text (description, flower, inflorescence, fruit, leaf, stem, habitat, toxicity, uses/`herbalism`, trivia).
- **36** app UI languages (34 catalog codes). Many languages have full seven-field body text. The rest show English body text, with that language's vernacular `label` and `names` when a source recorded them. There is no Google Translate cache.
- Community observations (1,509 public, last public stat date 2022) and photo search via Plant.id.

That is a hobby-scale, high-touch catalog. Adding a plant today means a local folder of photos, a Tkinter crop tool, a Wikidata/POWO scrape, and a Firebase write.

## The gap to "all plants"

| Dimension | Today | Encyclopedia |
|---|---|---|
| Scope | Flowering plants that fit a 4-step key | Vascular plants, then plants in general |
| Size | ~1.4k species | Hundreds of thousands of accepted names |
| Identity | Latin binomial as Firebase key | Stable taxon IDs (IPNI, POWO, WFO, GBIF) |
| Discovery | Precomputed 4-axis lists | Search, geography, taxonomy, image, traits |
| Ingest | Manual, one plant at a time | Automated, source-backed, reviewable |
| Text | English body, plus official text where a language is full-7; other UI languages fall back to English and keep their vernacular names | Seven fields in every UI language, sourced names |
| Media | Locally prepared WebP squares | Rights-aware media pipeline |
| Backend | One Realtime Database tree | Will not stay this shape at encyclopedia scale |

The current filter indexes (`lists_4_v2` ≈ 9.7k keys, `counts_4_v2` ≈ 11k keys) work because every combination of four small enums can be precomputed. That idea does not survive a 100× catalog, extra traits, or plants that have no petals.

## Principles for the journey

1. **Do not break the live identifier.** 1M+ people use the 4-step key. New encyclopedia work should sit beside it until it is better.
2. **Treat names as labels, IDs as identity.** `plants_v2/{Latin name}` already makes rename painful (`rename_plant.py` copies several trees).
3. **Cite sources.** Wikidata, POWO, IPNI, GBIF, and Wikipedia are already in the ingest path. Keep provenance as coverage grows.
4. **Human review stays in the loop** for photos, toxicity, and public observations. Automation prepares; it does not publish blindly.
5. **Scale the pipeline before scaling the catalog.** The Tkinter + BeautifulSoup flow is the bottleneck, not the Flutter screens.
6. **Do not ship Google Translate as catalog text.** Vernacular names stay sourced. Body text is written per UI language from the curated English (and that language’s floras). Never promote `{lang}-GT` into `translations/{lang}`.

## Suggested phases (not a schedule)

1. **Stabilize the present.** Docs, access to stores and Firebase, ship 8.0.7, understand data quality.
2. **Measure the catalog.** Coverage by family, region, language, missing sections, leftover `plants_v2` keys, observation health.
3. **Finish official body text.** The Translate API and `{lang}-GT` nodes are already gone. Remaining work is seven-field text in every UI language. [TRANSLATIONS.md](TRANSLATIONS.md). Notification copy in ingest still uses `GoogleTranslator` until that script is switched to stored strings.
4. **Harden identity.** Introduce a durable taxon id next to the Latin display name; stop treating rename as a multi-node copy.
5. **Grow ingest.** Replace one-off scripts with a repeatable plant job: fetch, normalize, review, publish — including every UI language in the same publish as English.
6. **Widen the product.** Trees, grasses, ferns, and plants without a flower key need different discovery than color/petals.
7. **Revisit storage.** Realtime Database plus denormalized lists is the right 2015–2022 design. It is not the encyclopedia design.

The next conversation after these docs should pick a phase, not all seven. Language retirement can run in parallel with catalog quality (English `/update-plant`) as long as a rewritten English plant is re-translated in the languages already finished.
