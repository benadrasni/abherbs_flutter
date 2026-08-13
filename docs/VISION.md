# Vision

## Destination

A comprehensive encyclopedia-like application for **all plants in the world**: species pages that a person can trust, find, and contribute to, on a phone.

The shipping product is already a real step toward that: a multilingual flower identifier with curated photos, botanical text, APG IV taxonomy, synonyms, and user observations. It is not yet an encyclopedia of plants. It is a **flower identification key** with a few thousand carefully prepared angiosperms.

## What exists today

- **1,413** curated flowering plants, each with photos, filter attributes, and a species page.
- Identification by **four human-visible traits**: color, habitat, petal type, TDWG level-2 region.
- Species pages with height, flowering months, toxicity class, APG IV path, IPNI / GBIF / USDA / Wikidata links, and sectioned text (description, flower, inflorescence, fruit, leaf, stem, habitat, toxicity, herbalism, trivia).
- **35** app UI languages; plant common names scraped from Wikidata into hundreds of language codes; missing body text filled by Google Translate and cached under `translations/{lang}-GT`.
- Community observations (1,509 public, last public stat date 2022) and photo search via Plant.id.
- A volunteer translation UI on whatsthatflower.com.

That is a hobby-scale, high-touch catalog. Adding a plant today means a local folder of photos, a Tkinter crop tool, a Wikidata/POWO scrape, and a Firebase write.

## The gap to "all plants"

| Dimension | Today | Encyclopedia |
|---|---|---|
| Scope | Flowering plants that fit a 4-step key | Vascular plants, then plants in general |
| Size | ~1.4k species | Hundreds of thousands of accepted names |
| Identity | Latin binomial as Firebase key | Stable taxon IDs (IPNI, POWO, WFO, GBIF) |
| Discovery | Precomputed 4-axis lists | Search, geography, taxonomy, image, traits |
| Ingest | Manual, one plant at a time | Automated, source-backed, reviewable |
| Text | Hand-written + translate-on-read | Structured fields + citations |
| Media | Locally prepared WebP squares | Rights-aware media pipeline |
| Backend | One Realtime Database tree | Will not stay this shape at encyclopedia scale |

The current filter indexes (`lists_4_v2` ≈ 9.7k keys, `counts_4_v2` ≈ 11k keys) work because every combination of four small enums can be precomputed. That idea does not survive a 100× catalog, extra traits, or plants that have no petals.

## Principles for the journey

1. **Do not break the live identifier.** 1M+ people use the 4-step key. New encyclopedia work should sit beside it until it is better.
2. **Treat names as labels, IDs as identity.** `plants_v2/{Latin name}` already makes rename painful (`rename_plant.py` copies several trees).
3. **Cite sources.** Wikidata, POWO, IPNI, GBIF, and Wikipedia are already in the ingest path. Keep provenance as coverage grows.
4. **Human review stays in the loop** for photos, toxicity, and public observations. Automation prepares; it does not publish blindly.
5. **Scale the pipeline before scaling the catalog.** The Tkinter + BeautifulSoup flow is the bottleneck, not the Flutter screens.

## Suggested phases (not a schedule)

1. **Stabilize the present.** Docs, access to stores and Firebase, ship 8.0.7, understand data quality.
2. **Measure the catalog.** Coverage by family, region, language, missing sections, leftover `plants_v2` keys, observation health.
3. **Harden identity.** Introduce a durable taxon id next to the Latin display name; stop treating rename as a multi-node copy.
4. **Grow ingest.** Replace one-off scripts with a repeatable plant job: fetch, normalize, review, publish.
5. **Widen the product.** Trees, grasses, ferns, and plants without a flower key need different discovery than color/petals.
6. **Revisit storage.** Realtime Database plus denormalized lists is the right 2015–2022 design. It is not the encyclopedia design.

The next conversation after these docs should pick phase 1 or 2 work, not all six.
