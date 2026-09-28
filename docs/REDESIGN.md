# Field guide redesign

Agreed 2026-09-27. Clickable phone mockup: [redesign/index.html](redesign/index.html). Open that file in a browser. Catalog photos, plates, names, and counts are the live ones. The photo of *Tanacetum corymbosum* is a stand-in for a photo the person took, because that species is not in the book.

The website is already the public reading room: paper `#f3eee4`, ink `#1a1612`, moss `#3e5344`, madder `#8e3b2a`, gold `#85603c`, Fraunces for names, Source Sans for text. The app becomes the field guide for that same book.

## Product

The app opens on **Find**, with three ways to a plant.

**Search** covers vernacular names, Latin names, families, and genera in the book. It is free.

**The camera** names any plant through Plant.id. A name we have written opens that species page. A name outside the book opens a short card: the photo just taken, the Latin name, a plain confidence (likely, possible, uncertain), and up to two other candidates. A curated species in the top three is offered as a full page beside the leading name. If the leading name is in the book, that page opens. Disease assessment is out of this redesign. It spends a second Plant.id credit.

**The key** is three steps, and the first step is already on Find. Color, then habitat, then petals. The four petal choices stay: 4 or fewer, 5, more than 5, zygomorphic. Distribution is no longer a step. It is a chip on the result list, labeled **Any region** until the person changes it. The chip can take a floristic region from the existing list, or from this phone’s location. The filter index already allows an empty region (`color_habitat_petal_`), so this does not need a new catalog index. White + meadow + more than 5 petals is `1_1_3_` and currently matches 93 plants. The same key with Middle Europe (`11`) matches 67. Those counts are the live lists.

The result list puts plants in flower this month first (`floweringFrom`–`floweringTo`), then the rest, each group alphabetical. A plant can carry more than one color, so a plain alphabetical list of white flowers can open on purple ones. The sort needs no new index.

Location is asked when they take a photo, or when they tap the region chip. It is not asked at launch. Plant.id receives coordinates only after that permission. If they refuse, the identification and the record have no place.

Once location is allowed, the phone keeps its floristic region, and the region chip starts on it the next time. The chip still shows the region by name, and **Any region** is one tap away. Only the region code is kept for the chip, not the coordinates.

The other tabs are **Book** and **Seen**. Book is families, genera, and the lists of flowers (`lists_custom/by language/{lang}`), using the same vernaculars as `translations_taxonomy`.

**Lists of flowers** also appear on Find as a row of cover cards under the recent finds. A list opens on its own page with the same Photos / Plates switch as the result list. Year campaigns (for example *Blume des Jahres*, ČBS *Rostlina roku*) run as a timeline, newest year first, with the source linked. Other lists are a grid. The first card is **New in the book**: the last 20 plants from `lists_custom/new`, grouped by the date they were added. A language without its own lists shows the English ones. The species page uses the same sections as the site: gallery and plate, names, flower, inflorescence, fruit, leaf, stem, habitat, toxicity, uses, trivia, taxonomy, distribution. The person icon holds the account, restore, language, and Field Guide.

## The meter

Photo identifications belong to an account.

| | Identifications |
|---|---|
| Before sign-in | 1, on an anonymous account |
| Each month, after sign-in | 5 |
| Extra, from a rewarded ad | up to 5 more that month |
| After those 10 | the camera offers only Field Guide |
| Field Guide, including the 7-day trial | unlimited, with a silent ceiling of 30 a day |

The app signs in anonymously with Firebase at first launch, so the Cloud Function counts the first identification like any other. Signing in links the anonymous account (`linkWithCredential`), so the first record and its allowance carry over. Reinstalling does not refresh the allowance.

The allowance drops when Plant.id returns a result, whether or not they keep the name. The exception is a photo that is probably not a plant: when Plant.id’s `is_plant` probability is below the threshold, the result says to try again closer, nothing is added to Seen, and the allowance stays. The daily ceiling still counts these calls. The threshold is a Cloud Function setting, not an app constant.

At zero included identifications, the sheet offers a verified rewarded ad (one more name, up to five in the month), Field Guide with a 7-day trial, and the key. The key never closes. At ten, the ad option is gone.

A free account that uses the full ten costs about €0.10–0.50 in Plant.id credits that month (about €0.01–0.05 a credit). The daily ceiling is what keeps a trial, or a script, from running an open bill. It is not shown in the interface.

Ads for free accounts are a banner on Find and on lists. The species page, the key steps, and the photo result stay clear. People who bought Remove ads, and Field Guide subscribers, see none. The rewarded ad is used only on the quota sheet, and only after the store’s server-side verification.

The Plant.id key lives on a Cloud Function in the existing Firebase project. The app never holds it. The function checks App Check, the account, the month’s allowance, the ad verification, and the store receipt, then calls Kindwise.

The function also counts leading names that are not in the book: Latin name, month, and count, in an Admin-only node. It stores no photo, place, or account. That tally is the candidate list for `/add-plant`: what people photograph that the book does not have yet.

## Seen

The moment a result appears, Seen gains a record: photo, time, place if it was allowed, and the leading name marked unconfirmed. Confirming, choosing another candidate, and deleting are one tap. Unconfirmed finds stay at the top.

Confirmed finds show in the book too. A species page has a **Seen by you** line with the date of the last find and how many there are. Result grids and lists mark plants they have seen, and a list header says how many of its plants they have seen (for example 3 of 93).

A find can also be added without the camera: **Add to Seen** on a species page, with a photo from the gallery or none. Date and place come from the photo’s EXIF when it has them. This is free and does not touch the allowance, because it does not call Plant.id. A place is optional; the old observation form required one.

Seen replaces Observations. Records live where observation records live today, in `observations/by users/{uid}`, for every signed-in account, so a new phone keeps the notebook. Photos stay on the phone. Field Guide adds the photos to the cloud, including those of names that are not in the book. Nothing already in Storage is deleted when a plan lapses; only new photos stop syncing.

A Seen record keeps every observation field (`plant`, `date`, `latitude`, `longitude`, `note`, `photoPaths`, `indoors`) and adds `confirmed`, `source` (`camera`, `manual`, `import`), and for camera finds the Plant.id candidates with their likelihood. `plant` may be a Latin name that is not in the book; readers keyed on catalog names (the per-plant index, stats, the reviewer) skip those.

### Sharing

A find is private until the person shares it. Any confirmed find of a species in the book has **Share**; a subscription is not needed. Unconfirmed finds and names outside the book cannot be shared, because there is no settled name and no species page to show them on.

The share sheet asks for consent every time: the photo is published under CC0, the note stays private, and the place is shown as country and month, not a pin. Sharing uploads the photo to `observations/{uid}/…` and writes the record to `observations/public` with status `review`, the same path uploads take today. Review stays as it is (`/review-observations`, Admin SDK sets `public` or `rejected`).

In Seen a shared find shows **In review**, **Shared**, or **Not accepted**. The person can withdraw a shared find at any time, which removes it from `observations/public`, as account deletion already does.

Accepted finds are **Sightings**: public, on species pages in the app and on the website, where public observations show today. The 1,778 accepted observations are Sightings already and carry over unchanged. **Seen** always means the person’s own notebook; **Sightings** always means what is public.

### Import

On the first launch after the update, existing observations become confirmed finds with `source: import`. A published observation keeps its state: `public` becomes **Shared**, `rejected` becomes **Not accepted**. There are 2,654 of them in 172 accounts (2026-09-27). Photos that were uploaded (published or rejected) are in Storage and load from there. Photos that were never uploaded exist only on the phone that took them; on any other phone the record shows without its photo.

## Field Guide

One new subscription, monthly and yearly (`field_guide_monthly`, `field_guide_yearly`), with a 7-day trial. It includes unlimited photo identification, no ads, sync of Seen, and offline packs of the book. An offline pack is one floristic region, the same regions as the region chip, so a walk in Middle Europe downloads Middle Europe rather than all 1,421 species. The phone’s own region is offered first. The price is the store price. This plan does not set a number.

The current photo-storage plans stay in the stores so existing subscribers and Restore keep working. An active `store_photos_monthly` or `store_photos_yearly` plan is treated as Field Guide. When it lapses, the account returns to the free allowance.

People who already paid keep what they paid for:

| Already purchased | Keeps |
|---|---|
| Remove ads (`no_ads`, `NoAds`) | no ads |
| Search | nothing extra to grant — search is free for everyone |
| Photo search (`search_by_photo`) | unlimited identification, on this phone |
| Observations | their observations, imported into Seen — Seen is now free for everyone |
| Offline | offline packs |
| Custom filter order | nothing to configure — the three-step key and the region chip are the default for everyone |
| Old paid app (`herbsplus`, `old version`) | no ads, unlimited identification, offline |

Sync remains Field Guide, including for those lifetime purchases. The old one-time products stay available to Restore and are no longer the way to buy.

## The website

The site stays the public reading room. Same species pages, same families and genera, no account, no camera, no quota. A shared find that lands in the book uses the existing plant URL. A find outside the book stays in Seen.

`/identify` on the site is still an invitation to install. After the app key is the one we mean, the same three steps and the same region chip can run there and finish on a species page. That is its own phase. The camera stays in the app.

New interface strings go into `lib/l10n/intl_*.arb`, then `flutter pub run intl_utils:generate`, then the website locale generator.

## Left alone

The Realtime Database trees stay. A Cloud Function is the new piece, not a new catalog store. The 4-step indexes stay in place and keep accepting an empty region. Catalog growth stays on its own track. Trees, grasses, and ferns are not part of this shell. Health assessment is not part of the camera.

## Build order

1. **Shell.** Find, Book, and Seen, the type and color, the species page, the three-step key, the region chip (with the remembered region), results in flower now first, lists of flowers, Seen by you, and free search. Seen replaces Observations here: the import, Add to Seen, Share with review, and Sightings on species pages. The current camera and purchases keep working underneath, so this can ship on its own.
2. **Field Guide.** The new subscription, the grandfather map, banners off the species page, the 7-day trial, and the allowance shown on the camera.
3. **Camera.** The Cloud Function, anonymous accounts at launch, the account allowance, no charge for a photo that is not a plant, verified ad grants, the tally of names outside the book, Plant.id for any plant, the full page or the short card, and the unconfirmed record in Seen.
4. **Carry.** Sync of Seen, offline packs by region, and a map of the person’s own finds.
5. **The key on the website.** The three steps on `/identify`, ending on the species page.

## Mockups

[redesign/index.html](redesign/index.html) is the clickable phone prototype of the agreed screens, in the website’s colors and type. Lists of flowers include the German year campaigns. The side notes switch signed-in, in-book, not-a-plant, quota, Field Guide, and German lists.

| Screen | What it shows |
|---|---|
| Find | Search, camera with its meter, and step 1 of the key already open |
| Search | Plants, families, and genera in one list |
| Key · habitat, Key · petals | Steps 2 and 3. Every habitat choice shows how many plants remain. Petals uses the live four choices |
| Results | White, meadow, more than 5 petals. 93 plants, or fewer once a region is set. Photos or plates |
| Region chip | Any region, a floristic region, or this phone’s location |
| Camera | Location asked once, at the first photo |
| Not a plant | Probably not a plant. Nothing saved, and the name is not used |
| Outside the book | *Tanacetum corymbosum*, with oxeye daisy and feverfew offered as full pages |
| Species from camera | Oxeye daisy, with the unconfirmed Seen bar |
| Species page | Same sections as the website. No ads |
| Seen | To confirm first, then the notebook by month |
| Share a find | CC0 consent, then review, then a public Sighting |
| Book | Families, genera, lists of flowers |
| List of flowers | A custom list. Year campaigns run newest first; New in the book by date |
| At the limit | Ad, Field Guide, or the key |
| Field Guide | What stays free, what the subscription adds, 7-day trial, restore |
| Person | Account, allowance, restore, language |
