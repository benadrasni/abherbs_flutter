import { createHash } from 'node:crypto';
import { initializeApp } from 'firebase-admin/app';
import { getDatabase, type Reference } from 'firebase-admin/database';
import { logger } from 'firebase-functions';
import { defineInt, defineSecret } from 'firebase-functions/params';
import { HttpsError, onCall, onRequest } from 'firebase-functions/v2/https';
import { verifyAdmobCallback } from './admob';
import {
  hasUnlimitedNames,
  isPlant,
  releaseAnonymousFree,
  rememberPhoto,
  reserveCall,
  takeAdGrant,
  takeAnonymousFree,
  takeFreeNotPlant,
  takeSharedSlot,
  utcDay,
  utcMonth,
  type QuotaState,
  type Refusal,
} from './quota';
import { plantIdBody, plantIdFinished, plantIdLanguage, plantIdSuggestions, plantIdUrl } from './plantid';
import {
  leadingScientificName,
  nameOutsideBook,
  nextNameTally,
  photoLookupKey,
  photoNameTallyPath,
} from './tally';

initializeApp();

const plantIdKey = defineSecret('PLANT_ID_KEY');
const isPlantThresholdPercent = defineInt('IS_PLANT_THRESHOLD_PERCENT', { default: 50 });
const freeNotPlantPerMonth = defineInt('FREE_NOT_PLANT_PER_MONTH', { default: 3 });
const dailyCeilingFree = defineInt('DAILY_CEILING_FREE', { default: 15 });
const dailyCeilingUnlimited = defineInt('DAILY_CEILING_UNLIMITED', { default: 30 });
const adGrantsPerMonth = defineInt('AD_GRANTS_PER_MONTH', { default: 5 });
const anonymousLifetimeCalls = defineInt('ANONYMOUS_LIFETIME_CALLS', { default: 3 });
const anonymousDailyCeiling = defineInt('ANONYMOUS_DAILY_CEILING', { default: 300 });

const maxImageChars = 8 * 1024 * 1024;
const cooldownMs = 5_000;
const repeatWindowMs = 24 * 60 * 60 * 1000;

const firebaseKey = /^[^.#$[\]/]{1,128}$/;

function logCredit(uid: string, feature: string): Promise<void> {
  return getDatabase().ref(`credits/${uid}/${Date.now()}`).set(feature);
}

async function addCredit(uid: string, feature: string): Promise<void> {
  await getDatabase()
    .ref(`users/${uid}/credits`)
    .transaction((current) => (typeof current === 'number' ? current : 0) + 1);
  await logCredit(uid, feature);
}

/** Spends one credit if the balance has one. The handler may first see null. */
async function spendCredit(uid: string): Promise<{ paid: boolean; left: number }> {
  let paid = false;
  const result = await getDatabase()
    .ref(`users/${uid}/credits`)
    .transaction((current) => {
      paid = false;
      if (typeof current !== 'number' || current <= 0) return current;
      paid = true;
      return current - 1;
    });
  const left = result.snapshot.val();
  return { paid: paid && result.committed, left: typeof left === 'number' ? left : 0 };
}

async function updateQuota<T>(
  ref: Reference,
  step: (current: QuotaState | null) => { state: QuotaState; value: T },
): Promise<T> {
  let value: T | undefined;
  await ref.transaction((current: QuotaState | null) => {
    const next = step(current);
    value = next.value;
    return next.state;
  });
  return value as T;
}

export const identifyPlant = onCall(
  {
    secrets: [plantIdKey],
    enforceAppCheck: true,
    memory: '512MiB',
    timeoutSeconds: 60,
    maxInstances: 10,
  },
  async (request) => {
    const uid = request.auth?.uid;
    if (!uid) throw new HttpsError('unauthenticated', 'sign-in');
    const image = request.data?.image;
    if (typeof image !== 'string' || image.length === 0 || image.length > maxImageChars) {
      throw new HttpsError('invalid-argument', 'image');
    }
    const rawLanguage = request.data?.language;
    const language =
      typeof rawLanguage === 'string' && /^[a-z]{2,3}(-[A-Za-z]{2,4})?$/.test(rawLanguage)
        ? rawLanguage
        : 'en';

    const db = getDatabase();
    const anonymous = request.auth?.token.firebase?.sign_in_provider === 'anonymous';
    const user = anonymous ? null : (await db.ref(`users/${uid}`).get()).val();
    const unlimited = hasUnlimitedNames(user);
    const hash = createHash('sha256').update(image).digest('base64url');
    const quotaRef = db.ref(`photo_quota/${uid}`);

    const refusal = await updateQuota<Refusal | undefined>(quotaRef, (current) => {
      const reserved = reserveCall(current, Date.now(), hash, {
        dailyCeiling: unlimited ? dailyCeilingUnlimited.value() : dailyCeilingFree.value(),
        cooldownMs,
        repeatWindowMs,
        lifetimeCeiling: anonymous ? anonymousLifetimeCalls.value() : undefined,
      });
      if ('refusal' in reserved) return { state: current ?? {}, value: reserved.refusal };
      return { state: reserved.state, value: undefined };
    });
    if (refusal) throw new HttpsError('resource-exhausted', refusal, { reason: refusal });

    const releaseFree = () =>
      quotaRef.transaction((current: QuotaState | null) => releaseAnonymousFree(current));
    if (anonymous) {
      const free = await updateQuota<boolean>(quotaRef, (current) => {
        const taken = takeAnonymousFree(current);
        return { state: taken.state, value: taken.free };
      });
      if (!free) throw new HttpsError('resource-exhausted', 'sign-in', { reason: 'sign-in' });
      let slot = false;
      await db.ref(`anonymous_daily/${utcDay(Date.now())}`).transaction((current) => {
        const taken = takeSharedSlot(current, anonymousDailyCeiling.value());
        slot = taken.taken;
        return taken.value;
      });
      if (!slot) {
        await releaseFree();
        throw new HttpsError('resource-exhausted', 'sign-in', { reason: 'sign-in' });
      }
    }

    let paid = false;
    let credits: number | undefined;
    if (!unlimited && !anonymous) {
      const spent = await spendCredit(uid);
      if (!spent.paid) {
        throw new HttpsError('resource-exhausted', 'no-credits', { reason: 'no-credits' });
      }
      paid = true;
      credits = spent.left;
    }

    let body: Record<string, unknown>;
    try {
      const response = await fetch(plantIdUrl(plantIdLanguage(language)), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Api-Key': plantIdKey.value() },
        body: JSON.stringify(plantIdBody(image)),
        signal: AbortSignal.timeout(30_000),
      });
      if (!response.ok) {
        const detail = (await response.text()).slice(0, 300);
        throw new Error(`Plant.id ${response.status} ${detail}`);
      }
      body = (await response.json()) as Record<string, unknown>;
      if (!plantIdFinished(body)) throw new Error('Plant.id incomplete');
    } catch (error) {
      logger.error('identifyPlant: Plant.id failed', { uid, error: String(error) });
      if (paid) {
        await addCredit(uid, 'refund: search by photo failed');
        credits = (credits ?? 0) + 1;
      }
      if (anonymous) await releaseFree();
      throw new HttpsError('unavailable', 'identify-failed');
    }

    await quotaRef.transaction((current: QuotaState | null) =>
      rememberPhoto(current, Date.now(), hash),
    );

    const suggestions = isPlant(body, isPlantThresholdPercent.value()) ? plantIdSuggestions(body) : [];

    let charged = paid;
    if (suggestions.length === 0 && paid) {
      const free = await updateQuota<boolean>(quotaRef, (current) => {
        const taken = takeFreeNotPlant(current, Date.now(), freeNotPlantPerMonth.value());
        return { state: taken.state, value: taken.free };
      });
      if (free) {
        await addCredit(uid, 'refund: not a plant');
        credits = (credits ?? 0) + 1;
        charged = false;
      }
    }
    if (charged) await logCredit(uid, 'search by photo');
    if (anonymous && suggestions.length === 0) await releaseFree();

    try {
      await tallyOutsideName(suggestions);
    } catch (error) {
      logger.error('identifyPlant: name tally failed', { error: String(error) });
    }

    return {
      isPlant: suggestions.length > 0,
      charged,
      credits,
      anonymousFreeUsed: anonymous && suggestions.length > 0,
      suggestions,
    };
  },
);

/**
 * Counts the leading Plant.id name when `search_photo` has no catalog path.
 * A species or a higher-taxon list is already in the book. The node is
 * `photo_name_tally/{yyyy-mm}/{key}` with the Latin name and the month's count.
 * No photo, place, or account is stored.
 */
async function tallyOutsideName(suggestions: Record<string, unknown>[]): Promise<void> {
  const name = leadingScientificName(suggestions);
  const key = name === null ? null : photoLookupKey(name);
  if (name === null || key === null) return;
  const db = getDatabase();
  const entry = (await db.ref(`search_photo/${key}`).get()).val();
  if (!nameOutsideBook(entry)) return;
  await db.ref(`${photoNameTallyPath}/${utcMonth(Date.now())}/${key}`).transaction((current) =>
    nextNameTally(current, name),
  );
}

/**
 * AdMob rewarded-ad server-side verification callback. The app sets
 * `ServerSideVerificationOptions(userId: uid)` on the rewarded ad. AdMob
 * retries on anything but 200, so handled duplicates and refusals answer 200.
 */
export const admobReward = onRequest({ maxInstances: 5 }, async (req, res) => {
  const raw = req.originalUrl;
  const query = raw.includes('?') ? raw.slice(raw.indexOf('?') + 1) : '';
  let params: URLSearchParams | null;
  try {
    params = await verifyAdmobCallback(query);
  } catch (error) {
    logger.error('admobReward: key fetch failed', { error: String(error) });
    res.status(503).send('retry');
    return;
  }
  if (!params) {
    res.status(403).send('bad signature');
    return;
  }
  const uid = params.get('user_id') ?? '';
  const transaction = params.get('transaction_id') ?? '';
  if (!firebaseKey.test(uid) || !firebaseKey.test(transaction)) {
    res.status(200).send('ignored');
    return;
  }

  const db = getDatabase();
  let fresh = false;
  await db.ref(`ad_rewards/${transaction}`).transaction((current) => {
    fresh = current === null;
    return current ?? { uid, at: Date.now() };
  });
  if (!fresh) {
    res.status(200).send('duplicate');
    return;
  }

  const granted = await updateQuota<boolean>(db.ref(`photo_quota/${uid}`), (current) => {
    const taken = takeAdGrant(current, Date.now(), adGrantsPerMonth.value());
    return { state: taken.state, value: taken.granted };
  });
  if (granted) await addCredit(uid, '1');
  res.status(200).send(granted ? 'ok' : 'month cap');
});
