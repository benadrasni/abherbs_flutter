# End-to-end user scenarios

Field Guide build (`redesign/field-guide`, 9.0.0). Run the purchase scenarios on a Play device with a license-tester account. The Pixel 10 Pro is the usual phone. The Pixel 9a emulator has no Play Billing, so it cannot buy. The App Store Field Guide products are priced and not submitted, so an iPhone can run the free and grandfather scenarios and cannot complete a new subscription.

Use a fresh install or a sandbox account for each new-user scenario. Do not spend the production Pixel account (`PGS88GCOzOPJWAaGMyyk66iKXAI3`) on delete, sign-out, or purchase tests.

`old version` is a server flag under `users/{uid}`. The phone cannot buy it and cannot write it. Prepare that account in the database before the pass. A purchase or Restore sends the store receipt to `submitPurchase`, which writes `users/{uid}/entitlements` when Apple or Google confirms it. The same account on the other phone unlocks from that record. A cancelled plan ends when the checked expiry passes. Record that in L1.

Search, the three-step key, every species page, Book, and Add to Seen are free for every account. Add to Seen does not call Plant.id and does not spend a name. Run checklist F once on a guest, then do not repeat it on every account unless a step says the book itself failed.

## What to look at

On each account, open Find, Person, the camera, Seen, and Offline. On Find, note whether a banner is on the first tab. Banners are not on Book or Seen.

Person allowance, in the English copy:

| What you see | Who |
|---|---|
| Names left, “1 name left”, and Sign in | Guest who still has the free name |
| “Sign in to name a photo” | Guest whose free name is spent, or a phone that has signed out |
| Names this month, a reset date | Signed in, no unlimited plan |
| Field Guide, then “no ads · Seen synced” | Field Guide or an active photo-storage plan |
| Unlimited names | Photo search |
| Unlimited names, then “no ads · Seen synced” | Old paid app |

The Field Guide card does not add the words “Unlimited names” unless that account also has photo search. The camera is still unlimited: no row of dots, and another photo still names. Offline is a row on Person for everyone. Download is offered only when the account may keep a pack. Otherwise the Offline screen offers Field Guide.

## Entitlement

| Account | Ads on Find | Photo names | Extra name from an ad | Seen on this phone | Seen photos on a second phone | Offline download | Field Guide row |
|---|---|---|---|---|---|---|---|
| G1 New guest | yes | 1, then sign in | no | yes, on the guest account | no | no | yes |
| S1 New, signed in | yes | 5 per UTC month | up to 5 more | yes, on the account | notebook only, no new photos | no | yes |
| S2 New Field Guide, trial or paid | no | unlimited, 30 a day | no | yes | yes, while the plan is active | yes | hidden |
| E1 Remove ads | no | 5 per month, plus ads | yes | yes | notebook only | no | yes |
| E2 Photo search | yes | unlimited, 30 a day | no | yes | notebook only | no | yes |
| E3 Offline | yes | 5 per month, plus ads | yes | yes | notebook only | yes | yes |
| E4 Observations, Search, or Custom filter | yes | 5 per month, plus ads | yes | yes | yes for Observations; notebook only for Search and Custom filter | no | yes |
| E5 Photo storage, monthly or yearly | no | unlimited, 30 a day | no | yes | yes | yes | hidden |
| E6 Old paid app | no | unlimited, 30 a day | no | yes | yes | yes | yes |
| E8 Stack of one-time products | no, if Remove ads is in the stack | unlimited if Photo search is in the stack, otherwise 5 | only when names are monthly | yes | notebook only | only if Offline is in the stack | yes |

“Notebook only” means the find’s name, time, and place come down on a second phone. The photo stays on the phone that took it. Field Guide, photo storage, the Observations purchase, and the old paid app copy new photos to `private/{uid}`. A lapsed Field Guide or photo-storage plan stops new copies and leaves the ones already stored. The Observations purchase and the old paid app do not lapse.

A guest is an anonymous Firebase account created once per install. The app treats that account as signed out. Signing out does not create another guest.

## Shared checklist F — the free book

1. Open the app. Find shows search and the first step of the key.
2. Search a Latin name and a vernacular. Open the species page. Order and family sit above the name. Notes, morphology, and Uses open when the plant has them.
3. Walk the key to a result grid. Open one plant.
4. Open Book, then New in the book, a family, and a genus.
5. On a species page, Add to Seen and choose a photo from this phone. Seen shows the find and that photo. Cancelling the picker saves nothing. The camera meter does not move.
6. Turn on airplane mode after a species page has loaded once. The page still opens from what this phone already has. Offline packs are a separate check.

## G1 — New guest

Setup: delete the app, install, do not sign in.

1. Run checklist F.
2. Person shows Names left, “1 name left”, the guest sentence, and Sign in. Field Guide and Offline are both rows. Restore purchases is there.
3. Find shows a banner.
4. The camera meter is one filled dot. Take a photo of a plant. The name opens the species page or Outside the book, and Seen gains an unconfirmed card. Person drops to “Sign in to name a photo”.
5. Take a second photo. The camera asks for sign-in and does not spend another name.
6. Confirm the first find if it is in the book. Share is not offered to this account, or the share stops because there is no signed-in account.
7. Open Offline. The screen offers Field Guide and does not start a download.

Pass: one name, then a sign-in wall on the camera. Search, the book, and Add to Seen never asked for an account.

## G2 — Guest, photo that is not a plant

Setup: a fresh guest who has not used the free name.

1. Photograph something that is not a plant.
2. The sheet says it is not a plant. Nothing is saved to Seen.
3. Person still shows 1 name left. A following photo of a real plant still uses that name.

The server gives the free name back when Plant.id finds no plant or the call fails. After three calls that are not a plant in the same UTC month, a later one can count. A guest only has the one free name, so stop at the first returned name.

## G3 — Guest creates an account

Setup: G1 after the free name is spent. Use an email that has never had an account. Google, Apple, and phone should land on the same allowance. Spot-check one of them.

1. Sign in from Person. Create the account when the email is unknown.
2. Person shows the account, Names this month, and “0” used. The guest’s Seen card is still there. The uid did not change: the anonymous account was linked.
3. The camera offers 5 names. Take one. The meter goes to 4 left, and `photo_quota/{uid}.namesUsed` is 1.
4. Sign out. Person returns to “Sign in to name a photo”. It does not offer another free guest name. The Seen list for the signed-out phone no longer shows the account’s finds.
5. Sign in again. The find and the spent monthly name are back.

Pass: the free name is not granted a second time on that uid. `photo_quota/{uid}.anonymousFreeUsed` stays true.

## G4 — Guest signs into an account that already exists

Setup: a fresh install, and an account that already has finds and a monthly count.

1. Use the free guest name and leave the card in Seen.
2. Sign in with the existing account.
3. Person shows that account’s monthly meter, not a fresh 5, and Seen shows that account’s notebook. The guest card is absent.
4. The guest uid is still an anonymous user with the free name spent. It is no longer this phone’s account.

Pass: the existing account is unchanged. The guest notebook stays on the guest uid.

## S1 — New, signed in, no purchase

Setup: a new email, or G3 before any purchase.

1. Run the camera through one real plant, one manual Add to Seen, and one name outside the book.
2. The outside card opens Outside the book, stays unconfirmed, and cannot be shared. Keep, It’s another one, and Delete work. Delete removes it from Seen.
3. Confirm an in-book find and share it. The sheet asks for CC0 every time. The note is not published. Seen shows In review.
4. Person still shows Field Guide. Offline offers Field Guide. Find shows a banner.
5. On a second phone, sign into the same account. The shared and private rows appear. A photo taken on the first phone does not download. Add to Seen on either phone saves only after a photo is chosen on that phone.
6. Spend the 5 included names. The camera offers a rewarded ad. Watch one. The meter gains one name (`adGrants` increases, up to 5). Spend that name.
7. After 5 included and 5 ad names, the camera offers Field Guide and no further ad. Search and the key still open.
8. Photograph the same plant again within a few seconds. The sheet says it is too soon. Send the same image again inside 24 hours. The sheet says it already saw that photo. Neither call spends a name.
9. On a name that is not a plant, the first three in the UTC month do not spend a name. The fourth does, and the sheet says it counted.

The silent ceiling is 15 Plant.id calls on a UTC day for this account. You do not need to hit it unless the meter and the refusals above already passed.

## S2 — New Field Guide, yearly trial

Setup: a new signed-in account that has never taken the Play trial on `field_guide_yearly`. Android only.

1. Person, Field Guide. Yearly is selected. The row shows the store price, about $24.99 in the US. The button says Start 7 days free.
2. Buy the yearly plan. Complete the Play trial sheet. Dismiss the store.
3. Person now says Field Guide, with “no ads · Seen synced”. The Field Guide row is gone. Restore purchases remains.
4. Find has no banner. The camera has no name dots. Take two photos. Both name, and `photo_quota` does not increment `namesUsed`.
5. Offline offers the whole book and a region. On Wi-Fi, start a small region, pause it, and resume it. A download on cellular shows the Wi-Fi line and does not save the pack.
6. Take a photo, then open the same account on a second phone that is also on this build. The photo arrives. `private/{uid}` has the object, and the private row gains `photoCloud` after the upload.
7. `users/{uid}/entitlements/products/field_guide_yearly` is `active: true`. `identifyPlant` treats that row as unlimited names. This phone may also list the id under `purchases`. That list does not unlock the other phone.

A monthly trial is the same scene with `field_guide_monthly` and the monthly price, about $2.99. Play counts the monthly trial and the yearly trial separately. An account that already used the yearly trial can still be offered the monthly trial.

## S3 — Switch yearly and monthly

Setup: S2, while the yearly trial is active.

1. Open Field Guide from a path that still shows the plans. Person hides the row once a plan is active, so use an account that owns monthly and buy yearly, or restore a monthly plan and then buy yearly from the page before the row hides.
2. Buying the other Field Guide plan replaces the one this account already has. Play shows a replacement, not a second subscription.
3. Person stays on Field Guide. Ads stay off. Photo sync stays on.
4. A photo-storage plan is not replaced by this purchase. Use E5 for that account. The Field Guide page treats photo storage as already covered and does not sell a second plan over it.

## E1 — Remove ads only

Setup: an account whose store restore returns `no_ads` on Android or `NoAds` on iOS, and nothing else.

1. Restore purchases on Person.
2. Find has no banner. Person still says Names this month, not Unlimited names, and still shows Field Guide.
3. The camera spends the monthly 5, then offers an ad.
4. Offline offers Field Guide.
5. A second phone shows the notebook and does not download new photos.

## E2 — Photo search only

Setup: restore `search_by_photo` only.

1. Person says Unlimited names. It does not say Seen synced. Field Guide is still a row.
2. Find still shows a banner.
3. The camera has no dots and keeps naming. The server ceiling is 30 calls a day.
4. Offline offers Field Guide. A second phone does not receive new photos.

## E3 — Offline only

Setup: restore `offline` only.

1. Person says Names this month. Find shows a banner. Field Guide is still a row.
2. Offline can download the book or a region without buying Field Guide.
3. Names stay on the monthly meter. A second phone does not receive new photos.

## E4 — Observations, Search, or Custom filter

Setup: three accounts, or one pass each, restoring `observations`, `search`, or `custom_filter` and nothing else.

1. Person says Names this month. On the Observations account it also says Seen synced. Find shows a banner. Offline offers Field Guide. Field Guide is still a row.
2. On the observations account, older private rows appear in Seen as confirmed finds. A missing `confirmed` field is already confirmed. A photo that was uploaded with a shared find loads from Storage. A photo still on this phone is copied to `private/{uid}`, including one taken before the purchase. A photo that never left the old phone is missing until that phone runs with the purchase.
3. Search and custom filter add nothing the free book does not already do. Search, the key, and Seen are free. They do not copy photos.

## E5 — Photo storage, monthly or yearly

Setup: an account with an active `store_photos_monthly` or `store_photos_yearly`. Restore if this phone does not already own it.

1. Person matches S2: Field Guide, “no ads · Seen synced”, no Field Guide row, no banner, unlimited camera, offline download, photos on a second phone.
2. The Field Guide page, if opened, does not sell `field_guide_monthly` or `field_guide_yearly` on top of this plan.
3. `users/{uid}/entitlements/products` has the photo-storage id `active: true`. `identifyPlant` treats that row as unlimited names.

Run monthly and yearly once each. They are the same Field Guide.

## E6 — Old paid app

Setup: `users/{uid}/old version` is true. Sign in on a fresh install of this build. There is no purchase to make.

1. Person says Unlimited names, then “no ads · Seen synced”. Field Guide is still a row. Seen says the photos are on this account’s devices, and it does not offer Field Guide again.
2. Find has no banner. The camera does not meter names.
3. Offline can download the book or a region. It does not offer Field Guide first.
4. Take a photo. The second phone shows the find and the photo. `private/{uid}` has the object.

## E8 — A stack of one-time products

Setup: one account restoring `no_ads`, `search_by_photo`, and `offline` together.

1. No banner. Unlimited names. Offline downloads. Field Guide remains, because Seen photos still do not sync.
2. Drop Photo search from a second account that has only `no_ads` and `offline`. Names go back to 5 a month. Ads stay off. Offline still downloads.

## U1 — Update from the store app

Setup: a phone that has the store app (8.3.x) with a signed-in account, some observations, and any old purchase. Install this build over it. Do not clear storage.

1. The same account is still signed in.
2. Old observations show in Seen as confirmed. Shared rows keep In review, Shared, or Not accepted.
3. Restore purchases. The columns in the entitlement table match what that account owned. A photo-storage plan becomes Field Guide without a new purchase.
4. Favorites and the language preference survive.

## R1 — Second phone and restore

Setup: S2 or E5 on phone A. Phone B is a fresh install.

1. Sign in on B before restoring. The notebook arrives. Photos that were copied while sync was on download. Photos from before that, and photos from E2, do not. E6 copies a new photo without a separate Field Guide purchase.
2. If B does not yet show the plan, Restore purchases. The plan returns, ads stay off, and a new photo on B uploads.
3. Sign out on B. The account’s finds leave the screen. Sign in. They return.

## R2 — Reinstall

1. On a guest phone, use the free name, delete the app, and install again. Person offers 1 name again. This is a new anonymous account. The old guest’s Seen does not return.
2. On S1, note the monthly count, delete the app, install, and sign in. The count and the notebook return. The free guest name is not added on top.

## R3 — Delete the account

Setup: a sandbox account you can afford to lose, with one private find, one shared find, and one photo in `private/{uid}`.

1. Delete the account from Person and confirm.
2. The phone returns to the signed-out state and does not offer a new guest free name on that same install.
3. The account’s private observations, the shared find, and `private/{uid}` are gone. `photo_quota/{uid}` may still exist. Record it if it does. Cleanup of that node is still open.

## L1 — Cancelled or expired plan

Setup: an Android sandbox Field Guide or photo-storage subscription. Cancel it and let the sandbox period end.

1. After the store reports the plan expired, force-stop the app and open it while online.
2. Record Person, the banner, the camera meter, and `users/{uid}/entitlements/products`.
3. The checked row is `active: false`. This phone and the other phone, signed into the same account, lose Field Guide. A brand-new account with no checked row is not subscribed.

## L2 — iPhone

Setup: this build on the iPhone 18 Pro simulator, or a device build.

1. Checklist F and S1 work. The simulator has no camera: add a photo to the library and set a location before the camera scenario.
2. Field Guide shows no buyable price, or “The store doesn’t have these plans yet.” The buy button stays off. There is no `.storekit` configuration in the project.
3. Restore of an older iOS purchase (`NoAds`, `search_by_photo`, `offline`, `observations`) follows E1–E4.

## Limits that apply on top of the account

| Check | Guest | Monthly account | Unlimited account |
|---|---|---|---|
| Not a plant | free name is returned | first 3 in the UTC month are free, then one name | does not spend a monthly name |
| Same photo inside 24 hours | refused | refused, name not spent | refused |
| Another call inside 5 seconds | refused | refused | refused |
| Calls in one UTC day | the shared anonymous pool, 300 for every guest together | 15 | 30 |
| Calls ever on that anonymous uid | 3, then sign-in | — | — |

The guest’s visible allowance is still one successful name. The extra calls are there so a failure or a not-a-plant answer can be given back.

## Result log

| Id | Account | Phone | Date | Pass | Note |
|---|---|---|---|---|---|
| F | | | | | |
| G1 | | | | | |
| G2 | | | | | |
| G3 | | | | | |
| G4 | | | | | |
| S1 | | | | | |
| S2 yearly | | | | | |
| S2 monthly | | | | | |
| S3 | | | | | |
| E1 | | | | | |
| E2 | | | | | |
| E3 | | | | | |
| E4 | | | | | |
| E5 monthly | | | | | |
| E5 yearly | | | | | |
| E6 | | | | | |
| E8 | | | | | |
| U1 | | | | | |
| R1 | | | | | |
| R2 | | | | | |
| R3 | | | | | |
| L1 | | | | | |
| L2 | | | | | |
