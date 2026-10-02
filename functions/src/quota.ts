/** Server-only state under `photo_quota/{uid}`. Days and months are UTC. */
export interface QuotaState {
  day?: string;
  dayCalls?: number;
  month?: string;
  notPlantFree?: number;
  adGrants?: number;
  lastCallAt?: number;
  lastHash?: string;
  lastHashAt?: number;
  totalCalls?: number;
  anonymousFreeUsed?: boolean;
}

export interface CallLimits {
  dailyCeiling: number;
  cooldownMs: number;
  repeatWindowMs: number;
  /** Calls an account may ever make; set for anonymous accounts only. */
  lifetimeCeiling?: number;
}

export type Refusal = 'cooldown' | 'daily-ceiling' | 'repeat-photo' | 'sign-in';

export function utcDay(now: number): string {
  return new Date(now).toISOString().slice(0, 10);
}

export function utcMonth(now: number): string {
  return new Date(now).toISOString().slice(0, 7);
}

/** Clears the day counter on a new UTC day and the month counters on a new month. */
export function rollOver(state: QuotaState | null, now: number): QuotaState {
  const next: QuotaState = { ...(state ?? {}) };
  const day = utcDay(now);
  if (next.day !== day) {
    next.day = day;
    next.dayCalls = 0;
  }
  const month = utcMonth(now);
  if (next.month !== month) {
    next.month = month;
    next.notPlantFree = 0;
    next.adGrants = 0;
  }
  return next;
}

/**
 * Counts one Plant.id call before it is made, whatever Plant.id answers.
 * The same photo within the repeat window is refused so a not-a-plant
 * answer cannot be replayed.
 */
export function reserveCall(
  state: QuotaState | null,
  now: number,
  hash: string,
  limits: CallLimits,
): { state: QuotaState } | { refusal: Refusal } {
  const next = rollOver(state, now);
  if (
    limits.lifetimeCeiling !== undefined &&
    (next.totalCalls ?? 0) >= limits.lifetimeCeiling
  ) {
    return { refusal: 'sign-in' };
  }
  if (next.lastCallAt !== undefined && now - next.lastCallAt < limits.cooldownMs) {
    return { refusal: 'cooldown' };
  }
  if (
    next.lastHash === hash &&
    next.lastHashAt !== undefined &&
    now - next.lastHashAt < limits.repeatWindowMs
  ) {
    return { refusal: 'repeat-photo' };
  }
  if ((next.dayCalls ?? 0) >= limits.dailyCeiling) {
    return { refusal: 'daily-ceiling' };
  }
  next.dayCalls = (next.dayCalls ?? 0) + 1;
  next.totalCalls = (next.totalCalls ?? 0) + 1;
  next.lastCallAt = now;
  return { state: next };
}

/**
 * An anonymous account's one free identification. It is taken before the
 * call and given back when Plant.id fails or finds no plant. Linking the
 * account on sign-in keeps the uid, so it is not handed out again.
 */
export function takeAnonymousFree(state: QuotaState | null): { state: QuotaState; free: boolean } {
  const next: QuotaState = { ...(state ?? {}) };
  if (next.anonymousFreeUsed === true) return { state: next, free: false };
  next.anonymousFreeUsed = true;
  return { state: next, free: true };
}

export function releaseAnonymousFree(state: QuotaState | null): QuotaState {
  return { ...(state ?? {}), anonymousFreeUsed: false };
}

/** Counts one anonymous free identification against the day's shared cap. */
export function takeSharedSlot(
  current: number | null,
  ceiling: number,
): { value: number | null; taken: boolean } {
  const used = typeof current === 'number' ? current : 0;
  if (used >= ceiling) return { value: current, taken: false };
  return { value: used + 1, taken: true };
}

export function rememberPhoto(state: QuotaState | null, now: number, hash: string): QuotaState {
  return { ...(state ?? {}), lastHash: hash, lastHashAt: now };
}

/** Uses one of the month's free not-a-plant answers, if any are left. */
export function takeFreeNotPlant(
  state: QuotaState | null,
  now: number,
  perMonth: number,
): { state: QuotaState; free: boolean } {
  const next = rollOver(state, now);
  const used = next.notPlantFree ?? 0;
  if (used >= perMonth) return { state: next, free: false };
  next.notPlantFree = used + 1;
  return { state: next, free: true };
}

export function takeAdGrant(
  state: QuotaState | null,
  now: number,
  perMonth: number,
): { state: QuotaState; granted: boolean } {
  const next = rollOver(state, now);
  const used = next.adGrants ?? 0;
  if (used >= perMonth) return { state: next, granted: false };
  next.adGrants = used + 1;
  return { state: next, granted: true };
}

/**
 * Plant.id v2 sends `is_plant_probability` and `is_plant`; v3 sends
 * `result.is_plant.probability` and `.binary`. A probability wins over the
 * flag so the threshold stays ours. A response with neither counts as a plant.
 */
export function isPlant(body: unknown, thresholdPercent: number): boolean {
  if (!body || typeof body !== 'object') return false;
  const top = body as Record<string, unknown>;
  const result = top.result as Record<string, unknown> | undefined;
  const nested = result?.is_plant as Record<string, unknown> | boolean | undefined;
  const probability =
    typeof top.is_plant_probability === 'number'
      ? top.is_plant_probability
      : nested && typeof nested === 'object' && typeof nested.probability === 'number'
        ? nested.probability
        : undefined;
  if (probability !== undefined) return probability * 100 >= thresholdPercent;
  if (typeof top.is_plant === 'boolean') return top.is_plant;
  if (typeof nested === 'boolean') return nested;
  if (nested && typeof nested === 'object' && typeof nested.binary === 'boolean') {
    return nested.binary;
  }
  return true;
}

const unlimitedProducts = [
  'search_by_photo',
  'store_photos_monthly',
  'store_photos_yearly',
  'field_guide_monthly',
  'field_guide_yearly',
];

/**
 * `old version` and `lifetime subscription` are server-set. `purchases` is a
 * product-ID list the app wrote itself, so it is trusted only until receipts
 * are verified on the server; the daily ceiling caps what a forged list gains.
 */
export function hasUnlimitedNames(user: Record<string, unknown> | null): boolean {
  if (!user) return false;
  if (user['old version'] === true || user['lifetime subscription'] === true) return true;
  const purchases = user.purchases;
  const owned = Array.isArray(purchases)
    ? purchases
    : purchases && typeof purchases === 'object'
      ? Object.values(purchases)
      : [];
  return owned.some((id) => typeof id === 'string' && unlimitedProducts.includes(id));
}
