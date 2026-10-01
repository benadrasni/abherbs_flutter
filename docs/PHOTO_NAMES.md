# Name it from a photo

The camera on Find (`guide_camera_title`, "Name it from a photo") names any plant from a photo with Plant.id (Kindwise). A name in the book opens its species page or list. A name outside the book opens the Outside the book page: the photo just taken, the Latin name, a plain confidence (likely, possible, uncertain), and up to two catalog species as full pages. That find is saved to Seen unconfirmed. Confirm, choose another candidate, and delete are on the page. A catalog species opened from the camera shows the same unconfirmed bar until it is kept.

Since 2026-09-30 the app never calls Plant.id itself. The Cloud Function `identifyPlant` holds the key, checks App Check and the account, counts the allowance, and calls Plant.id. Design background: `REDESIGN.md` (Camera).

## Who gets what

| Account | Photo names |
|---|---|
| Guest (anonymous account from first launch) | 1 free, then sign-in. At most 3 Plant.id calls per guest account, ever. |
| Signed in, no plan | 1 credit per name. Credits come from rewarded ads (max 5 a month) and older grants. |
| Photo search bought, Field Guide plan, `old version`, `lifetime subscription` | Unlimited, with a silent ceiling of 30 calls a day |

Rules that apply to every account:

- A photo Plant.id finds is not a plant (`is_plant` probability below `IS_PLANT_THRESHOLD_PERCENT`, or no suggestions) drops every suggestion. It is free for the first 3 each month (`FREE_NOT_PLANT_PER_MONTH`); after that it costs a credit and the sheet says it counted.
- Every Plant.id call counts against the daily ceiling (15 free, 30 unlimited), whatever the answer.
- 5 seconds between calls. The same photo (SHA-256 of the image) is refused for 24 hours.
- A failed Plant.id call refunds the credit or the guest's free name.
- All anonymous accounts together get at most 300 calls a day (`ANONYMOUS_DAILY_CEILING`). That caps what reinstalls cost.

## Guest accounts

- `Auth.startGuest()` signs in anonymously once per install (`guest_created` pref). Signing out does not create another guest.
- `Auth.appUser` and `Auth.subscribe` treat the anonymous account as signed out, so every `Auth.appUser != null` check still means a real sign-in. `Auth.guestUser` is the anonymous account.
- Sign-in links the guest (`linkWithCredential`), so the uid and the used free name carry over. A credential that already has an account signs in to it instead and the guest is left behind. `Auth.subscribe` uses `userChanges()` because linking does not fire `authStateChanges()`.
- The install remembers a used free name (`guest_free_used` pref); the camera also reads `photo_quota/{uid}/anonymousFreeUsed`.
- A reinstall or cleared app data creates a new guest with a new free name. Accepted; the shared anonymous ceiling limits the cost.
- Firebase Auth "Auto clean-up" of anonymous accounts stays off: it would hand a free name back every 30 days and orphan guest data. If clean-up is needed, write a scheduled function that deletes only anonymous accounts with no data.

## Server (`app/functions/`)

TypeScript, Node 22, firebase-functions 7, us-central1. `npm --prefix functions test` builds and runs the tests. Deploy with `firebase deploy --only functions` from `app/`.

- `identifyPlant` (callable, `enforceAppCheck: true`): input `{image: base64, language}`. Output `{isPlant, charged, credits, anonymousFreeUsed, suggestions}`. Refusals are `resource-exhausted` with `details.reason` one of `sign-in`, `no-credits`, `daily-ceiling`, `cooldown`, `repeat-photo`.
- Plant.id v3 `POST https://plant.id/api/v3/identification`. The body is `{images, similar_images: true}`. `details=common_names,url,description,taxonomy` and `language` are query parameters. `language` is a Plant.id code (`zh-hant` for this app's Chinese, `pt-BR` for Portuguese); other catalog languages omit it and the details come back in English. Suggestions are read from `result.classification.suggestions` and reshaped to `plant_details.scientific_name` before the app sees them. A reply whose `status` is not `COMPLETED` is a failed call and is refunded.
- `admobReward` (HTTPS): AdMob rewarded-ad server-side verification callback, `https://us-central1-abherbs-backend.cloudfunctions.net/admobReward`. Verifies the ECDSA signature against Google's verifier keys, ignores repeated `transaction_id`s, adds 1 credit up to 5 a month. The app sets `ServerSideVerificationOptions(userId: uid)` before showing the ad.
- `src/quota.ts` is the pure allowance logic, tested in `src/quota.test.ts`; `src/admob.ts` is the signature check.
- Secret `PLANT_ID_KEY` (Secret Manager). Limits in `functions/.env.abherbs-backend`: `IS_PLANT_THRESHOLD_PERCENT`, `FREE_NOT_PLANT_PER_MONTH`, `DAILY_CEILING_FREE`, `DAILY_CEILING_UNLIMITED`, `AD_GRANTS_PER_MONTH`, `ANONYMOUS_LIFETIME_CALLS`, `ANONYMOUS_DAILY_CEILING`. Change the file and redeploy.
- Unlimited is read from `users/{uid}`: `old version`, `lifetime subscription`, or `purchases` containing `search_by_photo`, `store_photos_monthly`, `store_photos_yearly`. `purchases` was written by old app versions and is not verified.

## Database

| Path | Writer | Client access |
|---|---|---|
| `photo_quota/{uid}` | `identifyPlant`, `admobReward` | owner read |
| `ad_rewards/{transactionId}` | `admobReward` | none |
| `anonymous_daily/{yyyy-mm-dd}` | `identifyPlant` | none |
| `users/{uid}/credits` | functions (grants, refunds); app spends 1 for text search | see rules below |
| `credits/{uid}/{ts}` | functions and app | owner read; new entries |

`photo_quota/{uid}`: `day`, `dayCalls`, `month`, `notPlantFree`, `adGrants`, `lastCallAt`, `lastHash`, `lastHashAt`, `totalCalls`, `anonymousFreeUsed`. Days and months are UTC.

Rules files:

- `firebase/database.rules.json`: live. The only photo change deployed so far is the `photo_quota/{uid}` owner read (2026-09-30).
- `firebase/database.rules.photo.json`: live rules plus the photo lock-down, to deploy after the app release. The app may only lower `users/{uid}/credits` by exactly 1 (text search) or delete it; `purchases` is delete-only; the credits log takes new entries only; `ad_rewards` and `anonymous_daily` are closed.
- `firebase/database.rules.target.json`: the later full tightening; has the same new nodes.

## App

- `lib/search/plant_id_search.dart`: `identifyPlantPhoto` calls the function and returns `PhotoIdentification` (results, `refusal`, `failed`, `charged`, `guestFreeUsed`). The old drawer screen `lib/search/search_photo.dart` uses only the results.
- `lib/guide/camera_page.dart`, `lib/guide/guide_camera.dart`, `lib/guide/outside_page.dart`: outcomes `species`, `list`, `outside`, `notPlant` (with `counted`), and the refusals `signIn`, `limit`, `tooSoon`, `samePhoto`, `pausedToday`. `outside` pushes Outside the book (`GuideOutside`). A catalog species from the camera opens `GuideSpeciesPage` with an unconfirmed bar. `openGuideCamera` opens the camera directly; the old purchase dialog and the photo-search promotion are gone from this path. Camera finds are private observations with `confirmed: false`, `source: camera`, and the Plant.id candidates. A photo from the roll keeps the date written in the photo (`DateTimeOriginal`, otherwise `DateTime`); a roll photo with no date, and a shutter photo, use the current time. Close on Outside the book returns to Find. Keep and Delete open Seen.
- `lib/guide/guide_person.dart`: `GuideAllowance.guest(free:)`.
- `lib/purchase/rewarded_ad.dart`: `tieRewardedAd`. `Auth.waitForAdReward` re-reads credits for a few seconds after the ad.
- `lib/main.dart`: App Check with Play Integrity and DeviceCheck in release, debug providers in debug builds. App Attest needs the capability on the App ID first.
- `lib/guide/guide_location.dart`: the camera's location lookup times out (15 s position, 10 s address) instead of hanging without a fix.

## Development

- A debug build prints "Firebase App Check debug token: …". Register it under the right app in Firebase console, App Check, Apps, Manage debug tokens, or with `firebase appcheck:debugtokens:create`. Delete tokens when a test device is gone. A simulator debug token for the iOS app was registered on 2026-09-30.
- The iOS simulator has no camera and no location: `xcrun simctl addmedia <udid> photo.jpg` adds a test photo; `xcrun simctl location <udid> set 48.1486,17.1077` sets a place.
- `firebase functions:log --only identifyPlant` shows calls; App Check and auth results appear as `verifications`.

## Status (2026-09-30)

Done: functions deployed with the secret, limits, and an artifact clean-up policy (1 day); AdMob callback URL set; App Check registered for Android and iOS; `photo_quota` owner read live; simulator test of the guest flow (free name, then sign-in).

Not released: the app changes, including Outside the book, are uncommitted in `app`.

Release order:

1. Ship the app version that calls `identifyPlant`.
2. When most users have updated, deploy `database.rules.photo.json` as `database.rules.json`, then rotate the Plant.id key at Kindwise and set it again with `firebase functions:secrets:set PLANT_ID_KEY`. Old versions call Plant.id with the key in `lib/keys.dart` until then. Remove `plantIdKey` from `lib/keys.dart`.

Open:

- Store receipt verification. New buyers of photo search or Field Guide are charged credits until the server can verify purchases.
- Anonymous accounts pass `auth != null` rules (favorites, public observations). Exclude them with `auth.token.firebase.sign_in_provider != 'anonymous'` where needed.
- Account deletion leaves `photo_quota/{uid}`.
- The tally of leading names not in the book (candidates for `/add-plant`) from `REDESIGN.md` is not built.
- The monthly allowance of 5 from `REDESIGN.md` is not built; signed-in free accounts use credits.
- Photo-search promotions would need a server setting.
