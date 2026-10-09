# Field guide redesign

Agreed 2026-09-27. Clickable mockup: [redesign/index.html](redesign/index.html), with a Device switch for the phone, iPad portrait, and iPad landscape. Open that file in a browser. Catalog photos, plates, names, and counts are the live ones. The photo of *Tanacetum corymbosum* is a stand-in for a photo the person took, because that species is not in the book.

The website is already the public reading room: paper `#f3eee4`, ink `#1a1612`, moss `#3e5344`, madder `#8e3b2a`, gold `#85603c`, Fraunces for names, Source Sans for text. The app becomes the field guide for that same book.

## Product

The app opens on **Find**, with three ways to a plant.

**Search** covers vernacular names, Latin names, families, and genera in the book. It is free.

**The camera** names any plant through Plant.id. A name we have written opens that species page. A name outside the book opens a short card: the photo just taken, the Latin name, a plain confidence (likely, possible, uncertain), and up to two other candidates. A curated species in the top three is offered as a full page beside the leading name. If the leading name is in the book, that page opens. Disease assessment is out of this redesign. It spends a second Plant.id credit.

**The key** is three steps, and the first step is already on Find. Color, then habitat, then petals. The four petal choices stay: 4 or fewer, 5, more than 5, zygomorphic. Distribution is no longer a step. It is a chip on the result list, labeled **Any region** until the person changes it. The chip can take a floristic region from the existing list, or from this phone’s location. The filter index already allows an empty region (`color_habitat_petal_`), so this does not need a new catalog index. White + meadow + more than 5 petals is `1_1_3_` and currently matches 93 plants. The same key with Middle Europe (`11`) matches 67. Those counts are the live lists.

Habitat asks where the plant is growing, and offers eight places as a 2×4 grid of tiles, each with a short line of examples: forest (woods, edges, clearings), meadow (pastures, hay meadows, lawns), dry and sunny (steppe, garrigue, dry slopes), fields and roadsides (weeds, paths, waste ground), water and wetland (ponds, banks, marshes), heath and bog (heather, peat, moorland), rocks and mountains (cliffs, scree, walls, alpine), coast (dunes, beaches, salt marsh). The codes that keep their meaning stay: 1 meadow, 3 wetland, 4 forest, 5 rocks. The new places take 7 dry and sunny, 8 fields and roadsides, 9 heath and bog, 10 coast. 2 garden and 6 tree are retired, so an old app never reads a reused code with a new meaning. Tree is what a plant is, not where it grows. Garden becomes a chip on the result list, **Wild and garden** until the person picks **Wild only**, which hides plants that are mainly grown in gardens. The choice is remembered like the region and applies only to the key's result list. Search and Book always show every plant, with a **Garden plant** tag on cultivated ones. A plant carries two or three habitats: where it is typically found, not everywhere it can grow. Every plant needs new habitat tags before this ships. Tagging rules, the `cultivated` flag, and the generated `plants_headers_v3` / `counts_4_v3` / `lists_4_v3` are in `HABITATS.md`. The counts on the mockup tiles are estimates for white flowers from the English habitat text, not live lists.

The result list puts plants in flower this month first (`floweringFrom`–`floweringTo`), then the rest, each group alphabetical. A plant can carry more than one color, so a plain alphabetical list of white flowers can open on purple ones. The sort needs no new index.

Location is asked when they take a photo, or when they tap the region chip. It is not asked at launch. Plant.id receives coordinates only after that permission. If they refuse, the identification and the record have no place.

Once location is allowed, the phone keeps its floristic region, and the region chip starts on it the next time. The chip still shows the region by name, and **Any region** is one tap away. Only the region code is kept for the chip, not the coordinates.

The other tabs are **Book** and **Seen**. Book is families, genera, and the lists of flowers (`lists_custom/by language/{lang}`), using the same vernaculars as `translations_taxonomy`. A heart on the species page marks that plant as a favorite. **Favorite flowers** is that person’s list. It leads the lists on Find and on Book only when at least one plant is marked, and it stays with the account, so signing out hides it.

**Lists of flowers** also appear on Find as a row of cover cards under the recent finds. A list opens on its own page with the same Photos / Plates switch as the result list. Year campaigns (for example *Blume des Jahres*, ČBS *Rostlina roku*) run as a timeline, newest year first, with the source linked. Other lists, such as vegetables and spices, use the result grid: in flower this month first. When a plant is marked, **Favorite flowers** is the first card and **New in the book** is the second. Otherwise the first card is **New in the book**: the last 15 to 25 plants from `lists_custom/new`, grouped by the date they were added. Book cards show four thumbnails from that list. A language without its own lists shows the English ones. The species page uses the same sections as the site: gallery and plate, names, flower, inflorescence, fruit, leaf, stem, habitat, toxicity, uses, trivia, taxonomy, distribution. The person icon holds the account, restore, language, theme, and Field Guide. Theme is Light, Dark, or System; System is the default and follows the phone.

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

The sign-in screen keeps today's four providers. Apple and Google come first as full-width buttons in their own brand styles; email and phone sit under them and open a short form. Above the buttons, three lines say what an account adds: 5 names a month, Seen on a new phone, and sharing finds. The screen also says the key and the book stay free without one. Terms of use and the privacy policy are linked under the buttons. Closing it returns to where it was opened.

On Person, the account header shows who is signed in. The first line is the display name from the provider. With no name, it shows the email; with no email, the phone number. The second line says how the person signed in, for example "anna.novak@gmail.com · Google", or "Email hidden by Apple" when Apple relays the address.

A signed-in Person has **Delete account**. It asks first. Confirming removes the account, observations, photos, and profile data. Purchases stay on the Apple ID and can be restored. A photo-storage subscription is cancelled in iOS Settings if they no longer want to be billed. The phone returns signed out. A guest does not see the row.

The allowance drops when Plant.id returns a result, whether or not they keep the name. The exception is a photo that is probably not a plant: when Plant.id’s `is_plant` probability is below the threshold, the result says to try again closer, nothing is added to Seen, and the allowance stays. The daily ceiling still counts these calls. The threshold is a Cloud Function setting, not an app constant.

At zero included identifications, the sheet offers a verified rewarded ad (one more name, up to five in the month), Field Guide with a 7-day trial, and the key. The key never closes. At ten, the ad option is gone.

A free account that uses the full ten costs about €0.10–0.50 in Plant.id credits that month (about €0.01–0.05 a credit). The daily ceiling is what keeps a trial, or a script, from running an open bill. It is not shown in the interface.

Ads for free accounts are a banner on Find and on lists. On Find and the habitat and petal steps of the key, the banner is pinned above the tab bar. The species page and the photo result stay clear. People who bought Remove ads, and Field Guide subscribers, see none. The rewarded ad is used only on the quota sheet, and only after the store’s server-side verification.

The Plant.id key lives on a Cloud Function in the existing Firebase project. The app never holds it. The function checks App Check, the account, the month’s allowance, the ad verification, and the store receipt, then calls Kindwise.

The function also counts leading names that are not in the book: Latin name, month, and count, in an Admin-only node. It stores no photo, place, or account. That tally is the candidate list for `/add-plant`: what people photograph that the book does not have yet.

## Seen

The moment a result appears, Seen gains a record: photo, time, place if it was allowed, and the leading name marked unconfirmed. Confirming, choosing another candidate, and deleting are one tap. Unconfirmed finds stay at the top.

Confirmed finds show in the book too. A species page has a **Seen by you** line with the date of the last find and how many there are. Result grids and lists mark plants they have seen, and a list header says how many of its plants they have seen (for example 3 of 93).

A find can also be added without the camera: **Add to Seen** on a species page opens this phone’s photos and saves the picture you choose. The anonymous guest can do this; the find is stored on that guest account. Date and place come from that photo’s EXIF when it has them. This is free and does not touch the allowance, because it does not call Plant.id. A place is optional; the old observation form required one.

Seen replaces Observations. Records live where observation records live today, in `observations/by users/{uid}`, for every signed-in account, so a new phone keeps the notebook. Photos stay on the phone. While Field Guide is active, or the account owns the Observations purchase, the app copies each local photo to `private/{uid}/…` in Storage, including a Latin name that is not in the book. That prefix is readable only by the account. The object key mirrors `observations/{uid}/…`. Shared Sightings stay on the public `observations/{uid}/…` path. A second phone saves the file into its documents directory, including after the plan lapses. Nothing already in Storage is deleted when a plan lapses; only new photos stop syncing. Deleting a find, or the account, deletes its private objects.

A Seen record keeps every observation field (`plant`, `date`, `latitude`, `longitude`, `note`, `photoPaths`, `indoors`) and adds `confirmed`, `source` (`camera`, `manual`, `import`), and for camera finds the Plant.id candidates with their likelihood. After every photo of that find is in `private/{uid}/`, the private row also has `photoCloud: true`. Share does not copy that flag. A full save that rewrites the row omits it until the next upload. `plant` may be a Latin name that is not in the book; readers keyed on catalog names (the per-plant index, stats, the reviewer) skip those.

### Sharing

A find is private until the person shares it. A confirmed find of a species in the book has **Share** when its photo is on this phone, in private Storage, or already published. A path left on the row after a fresh install is not a photo, and that row has no Share. A subscription is not needed. Unconfirmed finds and names outside the book cannot be shared, because there is no settled name and no species page to show them on.

The share sheet asks for consent every time: the photo is published under CC0, the note stays private, and the place is shown as country and month, not a pin. Sharing uploads the photo to `observations/{uid}/…` and writes the record to `observations/public` with status `review`, the same path uploads take today. Review stays as it is (`/review-observations`, Admin SDK sets `public` or `rejected`).

In Seen a shared find shows **In review**, **Shared**, or **Not accepted**. The person can withdraw a shared find at any time, which removes it from `observations/public`, as account deletion already does. Every confirmed row also has **Delete**, and that sheet asks first. A private find leaves Seen. A Sighting leaves Seen and Sightings, including the public photo. A find in review, or one that was not accepted, leaves Seen and the copy that was sent. Withdrawing stays separate: the find remains in Seen and only the public record goes.

Accepted finds are **Sightings**: public, on species pages in the app and on the website, where public observations show today. The 1,778 accepted observations are Sightings already and carry over unchanged. **Seen** always means the person’s own notebook; **Sightings** always means what is public.

### Import

On the first launch after the update, existing observations become confirmed finds with `source: import`. A published observation keeps its state: `public` becomes **Shared**, `rejected` becomes **Not accepted**. There are 2,654 of them in 172 accounts (2026-09-27). Photos that were uploaded (published or rejected) are in Storage and load from there. Photos that were never uploaded exist only on the phone that took them; on any other phone the record shows without its photo.

## Field Guide

One new subscription, monthly and yearly (`field_guide_monthly`, `field_guide_yearly`), with a 7-day trial. It includes unlimited photo identification, no ads, sync of Seen, and offline copies of the book. Offline is the whole book, or a floristic region. The regions are the ones the filter already uses: eight parts of the world, each opening the same level-2 regions as the region chip. The phone’s own region is offered first. A plant that grows in two selected regions is stored once. Antarctic is not a pack: the continent has no species, and every subantarctic species is also recorded somewhere else. Sizes on the screen are the pictures (photos, the unsuffixed plate, and the range map). The 1,433 species in `plants_headers` average 0.66 MB, so the book is about 950 MB. Middle Europe alone is about 730 MB, because 1,105 of the 1,433 species occur there. The price is the store price. This plan does not set a number.

### Offline updates

After a pack is on the phone, later catalog changes arrive as one update. The Offline screen shows it under what is already stored, with its size. Person shows the same size. Nothing is downloaded until the person taps Update. The download uses Wi-Fi and can be paused, the same way as the first download.

A new plant is part of the update when it occurs in a pack already on the phone. A plant recorded only in a region they did not download is not. Everything includes every new plant. A new photo, plate, or map on a plant already stored fetches only the changed files. A picture removed from the plant is deleted from the phone. Several plants fold into that one line. A plant that leaves their region stays until they remove the pack. The words for the plants in the update come with it and barely change the size.

Two records make the line. The phone stores the last change it applied, and a stamp for each plant it has. The stamp covers that plant’s photos, plate, and map. The catalog keeps a change list. Publishing a species, or replacing a photo, plate, or map, appends one entry: the plant id, whether the plant was added or its pictures changed, and the new stamp. The Offline screen reads the entries after the phone’s mark, keeps the ones that fall in a stored pack, and adds up their size. After the download, the mark moves forward and the new stamps are stored.

`plants_to_update` stays the ordered list of the book. Its count shows that new names were appended. It does not record that an older plant received a new plate. The change list does.

The current photo-storage plans stay in the stores so existing subscribers and Restore keep working. An active `store_photos_monthly` or `store_photos_yearly` plan is treated as Field Guide. When it lapses, the account returns to the free allowance.

People who already paid keep what they paid for:

| Already purchased | Keeps |
|---|---|
| Remove ads (`no_ads`, `NoAds`) | no ads |
| Photo search (`search_by_photo`) | unlimited identification |
| Observations | Seen photos on every phone, including photos already on the phone. The notebook itself is free for everyone |
| Offline | offline packs |
| Photo storage (`store_photos_monthly`, `store_photos_yearly`), while the plan is active | Field Guide |
| Old paid app (`herbsplus`, `old version`) | no ads, unlimited identification, offline, Seen photos on every phone |

Search and custom filter order grant nothing. A stored lifetime subscription flag is ignored. The old paid app is not Field Guide, and that row stays available. Seen photos and the offline book are already included. The old one-time products stay available to Restore and are no longer the way to buy.

## The website

The site stays the public reading room. Same species pages, same families and genera, no account, no camera, no quota. A shared find that lands in the book uses the existing plant URL. A find outside the book stays in Seen.

`/identify` on the site is still an invitation to install. After the app key is the one we mean, the same three steps and the same region chip can run there and finish on a species page. That is its own phase. The camera stays in the app.

New interface strings go into `lib/l10n/intl_*.arb`, then `flutter pub run intl_utils:generate`, then the website locale generator.

## How we build it

New screens, not edits to the ones that ship today. Find, Book, Seen, the species page, the three-step key, the region chip, search, the camera result, and Field Guide are new pages. The live screens stay: the color, habitat, petal, and region steps, the result list, plant detail, search, the drawer, settings, purchases, and observations. The root can open the new shell. Those old pages are not rewritten to become it.

Reuse the current Firebase reads and helpers when a new page can call them as they are: `lists_4_v2`, `lists_custom`, `translations`, `translations_taxonomy`, `observations`, `filter_utils`, and the prefs and language helpers. A new page gets its own helper or API only when nothing suitable already returns what it needs.

Database additions and changes are allowed when a new page needs a field or node the current trees do not have. The Seen fields (`confirmed`, `source`, candidates) are that kind of addition. The 4-step indexes stay in place and keep accepting an empty region. Catalog growth stays on its own track. Trees, grasses, and ferns are not part of this shell. Health assessment is not part of the camera. The Plant.id key stays on a Cloud Function.

## Build order

1. **Shell.** Find, Book, and Seen, the type and color, the species page, the three-step key, the region chip (with the remembered region), results in flower now first, lists of flowers, Seen by you, and free search. Seen replaces Observations here: the import, Add to Seen, Share with review, and Sightings on species pages. The current camera and purchases keep working underneath, so this can ship on its own.
2. **Field Guide.** The new subscription, the grandfather map, banners off the species page, the 7-day trial, and the allowance shown on the camera.
3. **Camera.** The Cloud Function, anonymous accounts at launch, the account allowance, no charge for a photo that is not a plant, verified ad grants, the tally of names outside the book, Plant.id for any plant, the full page or the short card, and the unconfirmed record in Seen.
4. **Carry.** Private Seen photos, including names outside the book, copy to `private/{uid}/` while Field Guide is active. Still to build: floristic-region packs, the change list for plants added or given new pictures after a pack is stored, and a map of the person’s own finds. The whole-book download is already in the app.
5. **The key on the website.** The three steps on `/identify`, ending on the species page.

## Mockups

[redesign/index.html](redesign/index.html) is the clickable phone prototype of the agreed screens, in the website’s colors and type. Lists of flowers include the German year campaigns. The side notes switch signed-in, in-book, not-a-plant, quota, Field Guide, and German lists.

| Screen | What it shows |
|---|---|
| Find | Search, camera with its meter, and step 1 of the key already open. Favorite flowers leads the list covers when any plant is marked |
| Search | Plants, families, and genera in one list |
| Key · habitat, Key · petals | Steps 2 and 3. Eight habitat tiles with examples and estimated counts. Petals uses the live four choices |
| Results | White, meadow, more than 5 petals. 93 plants, or fewer once a region is set or Wild only is on. Photos or plates |
| Region chip | Any region, a floristic region, or this phone’s location |
| Camera | Location asked once, at the first photo |
| Not a plant | Probably not a plant. Nothing saved, and the name is not used |
| Outside the book | *Tanacetum corymbosum*, with oxeye daisy and feverfew offered as full pages |
| Species from camera | Oxeye daisy, with the unconfirmed Seen bar |
| Species page | Same sections as the website. A heart marks the plant as a favorite. Flower and Inflorescence open the diagrams. No ads |
| Flower schema | Numbered plate of a complete flower, and the seventeen part names |
| Inflorescences | The seventeen types. Opened from a species page, that plant’s stored type is marked; the first is the primary |
| Seen | To confirm first, then the notebook by month. Delete on a confirmed find asks first |
| Share a find | CC0 consent, then review, then a public Sighting |
| Seen · delete a Sighting | A public find leaves Seen and Sightings. In review or not accepted, the copy you sent goes too |
| Statistics · your finds | Counts, first and last, years, and countries with flags. Finds in Middle Europe are shown as Slovakia. Indoor finds are left out |
| Statistics · Sightings | The same page for accepted finds. 1,778 sightings, 630 plants, 56 people. Years, and every country with its flag. Country, not a pin |
| Book | Families, genera, lists of flowers. Favorite flowers leads the lists when any plant is marked |
| List of flowers | New in the book by date (last 15 to 25). Year campaigns newest first. Other lists use the result grid |
| List · Favorites | The plants marked with the heart. The card is absent until one is marked, and it hides when signed out |
| At the limit | Ad, Field Guide, or the key |
| Field Guide | What stays free, what the subscription adds, 7-day trial, restore |
| Offline | The whole book, or a floristic region. Each row shows the plants and the space the pictures take. The phone’s region is offered first |
| Offline · downloading | Middle Europe, about halfway, in megabytes |
| Offline · add a region | Middle Europe is already stored. Adding the Northeast shows only the plants that are not |
| Person | Account and the name allowance. Field Guide is one perk line, and that row hides once subscribed. Language sits on the right. Ad privacy shows where consent can be changed. Dangerous zone is above Delete account. The version copies on tap. A guest does not see Delete account |
| Person · delete account | The account, observations, photos, and profile go. Purchases stay and can be restored |
