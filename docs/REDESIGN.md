# Field guide redesign

Agreed 2026-09-27. Clickable phone mockups: [redesign/index.html](redesign/index.html). Open that file in a browser. Catalog photos and English names in the mockups are the live ones. The houseplant picture is a stand-in for a photo the person took, because that species is not in the book.

The website is already the public reading room: paper `#f3eee4`, ink `#1a1612`, moss `#3e5344`, madder `#8e3b2a`, gold `#85603c`, Fraunces for names, Source Sans for text. The app becomes the field guide for that same book.

## Product

The app opens on **Find**, with three ways to a plant.

**Search** covers vernacular names, Latin names, families, and genera in the book. It is free.

**The camera** names any plant through Plant.id. A name we have written opens that species page. A name outside the book opens a short card: the photo just taken, the Latin name, a plain confidence (likely, possible, uncertain), and up to two other candidates. A curated species in the top three is offered as a full page beside the leading name. If the leading name is in the book, that page opens. Disease assessment is out of this redesign. It spends a second Plant.id credit.

**The key** is three steps, and the first step is already on Find. Color, then habitat, then petals. The four petal choices stay: 4 or fewer, 5, more than 5, zygomorphic. Distribution is no longer a step. It is a chip on the result list, labeled **Any region** until the person changes it. The chip can take a floristic region from the existing list, or from this phone’s location. The filter index already allows an empty region (`color_habitat_petal_`), so this does not need a new catalog index. White + meadow + more than 5 petals is `1_1_3_` and currently matches 93 plants. The same key with Middle Europe (`11`) matches 67. Those counts are the live lists.

Location is asked when they take a photo, or when they tap the region chip. It is not asked at launch. Plant.id receives coordinates only after that permission. If they refuse, the identification and the record have no place.

The other tabs are **Book** and **Seen**. Book is families, genera, and the editorial lists, using the same vernaculars as `translations_taxonomy`. The species page uses the same sections as the site: gallery and plate, names, flower, inflorescence, fruit, leaf, stem, habitat, toxicity, uses, trivia, taxonomy, distribution. The person icon holds the account, restore, language, and Field Guide.

## The meter

Photo identifications belong to an account.

| | Identifications |
|---|---|
| Before sign-in | 1, saved on the phone |
| Each month, after sign-in | 5 |
| Extra, from a rewarded ad | up to 5 more that month |
| After those 10 | the camera offers only Field Guide |
| Field Guide, including the 7-day trial | unlimited, with a silent ceiling of 30 a day |

The first record attaches to the account at sign-in. Reinstalling does not refresh the allowance. The allowance drops when Plant.id returns a result, whether or not they keep the name.

At zero included identifications, the sheet offers a verified rewarded ad (one more name, up to five in the month), Field Guide with a 7-day trial, and the key. The key never closes. At ten, the ad option is gone.

A free account that uses the full ten costs about €0.10–0.50 in Plant.id credits that month (about €0.01–0.05 a credit). The daily ceiling is what keeps a trial, or a script, from running an open bill. It is not shown in the interface.

Ads for free accounts are a banner on Find and on lists. The species page, the key steps, and the photo result stay clear. People who bought Remove ads, and Field Guide subscribers, see none. The rewarded ad is used only on the quota sheet, and only after the store’s server-side verification.

The Plant.id key lives on a Cloud Function in the existing Firebase project. The app never holds it. The function checks App Check, the account, the month’s allowance, the ad verification, and the store receipt, then calls Kindwise.

## Seen

The moment a result appears, Seen gains a record: photo, time, place if it was allowed, and the leading name marked unconfirmed. Confirming, choosing another candidate, and deleting are one tap. Unconfirmed finds stay at the top.

The record stays on the phone for everyone. Field Guide copies it across devices, including the photo and including names that are not in the book. Seen is private. Public sharing, and the old condition that a subscription publish the photo under CC0, are out of this redesign.

## Field Guide

One new subscription, monthly and yearly (`field_guide_monthly`, `field_guide_yearly`), with a 7-day trial. It includes unlimited photo identification, no ads, sync of Seen, and offline packs of the book. The price is the store price. This plan does not set a number.

The current photo-storage plans stay in the stores so existing subscribers and Restore keep working. An active `store_photos_monthly` or `store_photos_yearly` plan is treated as Field Guide. When it lapses, the account returns to the free allowance.

People who already paid keep what they paid for:

| Already purchased | Keeps |
|---|---|
| Remove ads (`no_ads`, `NoAds`) | no ads |
| Search | nothing extra to grant — search is free for everyone |
| Photo search (`search_by_photo`) | unlimited identification, on this phone |
| Observations | the local notebook they already had — the local notebook is now free for everyone |
| Offline | offline packs |
| Custom filter order | nothing to configure — the three-step key and the region chip are the default for everyone |
| Old paid app (`herbsplus`, `old version`) | no ads, unlimited identification, offline, local notebook |

Sync remains Field Guide, including for those lifetime purchases. The old one-time products stay available to Restore and are no longer the way to buy.

## The website

The site stays the public reading room. Same species pages, same families and genera, no account, no camera, no quota. A shared find that lands in the book uses the existing plant URL. A find outside the book stays in Seen.

`/identify` on the site is still an invitation to install. After the app key is the one we mean, the same three steps and the same region chip can run there and finish on a species page. That is its own phase. The camera stays in the app.

New interface strings go into `lib/l10n/intl_*.arb`, then `flutter pub run intl_utils:generate`, then the website locale generator.

## Left alone

The Realtime Database trees stay. A Cloud Function is the new piece, not a new catalog store. The 4-step indexes stay in place and keep accepting an empty region. Catalog growth stays on its own track. Trees, grasses, and ferns are not part of this shell. Health assessment is not part of the camera.

## Build order

1. **Shell.** Find, Book, and Seen, the type and color, the species page, the three-step key, the region chip, and free search. The current camera and purchases keep working underneath, so this can ship on its own.
2. **Field Guide.** The new subscription, the grandfather map, banners off the species page, the 7-day trial, and the allowance shown on the camera.
3. **Camera.** The Cloud Function, the account allowance, verified ad grants, Plant.id for any plant, the full page or the short card, and the unconfirmed record in Seen.
4. **Carry.** Sync of Seen, offline packs, and a map of the person’s own finds.
5. **The key on the website.** The three steps on `/identify`, ending on the species page.

## Mockups

[redesign/index.html](redesign/index.html) is a clickable phone prototype of the agreed screens, in the website’s colors and type.

| Screen | What it shows |
|---|---|
| Find | Search, camera with 4 of 5 left, color already tappable, Any region, recent finds |
| Habitat, Petals | Steps 2 and 3. Petals uses the live four choices |
| Results | White, meadow, more than 5 petals. 93 plants, or 67 in Middle Europe. Real species from `lists_4_v2/1_1_3_` |
| Species | Daisy, with the unconfirmed Seen bar. Height and months are the live record |
| Outside the book | *Epipremnum aureum*, which is not in the catalog, with *Monstera deliciosa* offered because it is |
| Seen | Unconfirmed finds first, then confirmed ones |
| Book | Families with the English vernaculars already in `translations_taxonomy` |
| At the limit | Ad, Field Guide, or the key |
| Field Guide | What stays free, what the subscription adds, 7-day trial, restore |
