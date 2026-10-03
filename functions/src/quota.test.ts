import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  hasUnlimitedNames,
  isPlant,
  meterCounts,
  namesRemaining,
  releaseAnonymousFree,
  releaseName,
  rememberPhoto,
  reserveCall,
  takeAdGrant,
  takeAnonymousFree,
  takeFreeNotPlant,
  takeName,
  takeSharedSlot,
  type QuotaState,
} from './quota';

const limits = { dailyCeiling: 3, cooldownMs: 5_000, repeatWindowMs: 60_000 };
const noon = Date.parse('2026-09-30T12:00:00Z');

function reserved(result: ReturnType<typeof reserveCall>): QuotaState {
  if ('refusal' in result) assert.fail(`refused: ${result.refusal}`);
  return result.state;
}

test('counts every call against the daily ceiling', () => {
  let state: QuotaState | null = null;
  for (let i = 0; i < 3; i++) {
    state = reserved(reserveCall(state, noon + i * 10_000, `h${i}`, limits));
  }
  assert.deepEqual(reserveCall(state, noon + 40_000, 'h9', limits), { refusal: 'daily-ceiling' });
});

test('the ceiling resets on a new UTC day', () => {
  const full: QuotaState = { day: '2026-09-30', dayCalls: 3, month: '2026-09' };
  const next = reserved(reserveCall(full, Date.parse('2026-10-01T00:00:01Z'), 'h', limits));
  assert.equal(next.dayCalls, 1);
  assert.equal(next.day, '2026-10-01');
});

test('refuses calls inside the cooldown', () => {
  const state = reserved(reserveCall(null, noon, 'a', limits));
  assert.deepEqual(reserveCall(state, noon + 1_000, 'b', limits), { refusal: 'cooldown' });
});

test('refuses the same photo inside the repeat window', () => {
  const state = rememberPhoto(reserved(reserveCall(null, noon, 'a', limits)), noon, 'a');
  assert.deepEqual(reserveCall(state, noon + 10_000, 'a', limits), { refusal: 'repeat-photo' });
  assert.ok('state' in reserveCall(state, noon + 61_000, 'a', limits));
});

test('free not-a-plant answers stop at the month cap and reset next month', () => {
  let state: QuotaState | null = null;
  const frees: boolean[] = [];
  for (let i = 0; i < 4; i++) {
    const taken = takeFreeNotPlant(state, noon, 3);
    state = taken.state;
    frees.push(taken.free);
  }
  assert.deepEqual(frees, [true, true, true, false]);
  assert.equal(takeFreeNotPlant(state, Date.parse('2026-10-01T00:00:00Z'), 3).free, true);
});

test('a signed-in account has five names, then one more for each ad', () => {
  let state: QuotaState | null = null;
  for (let i = 0; i < 5; i++) {
    const taken = takeName(state, noon);
    assert.equal(taken.taken, true);
    state = taken.state;
  }
  assert.equal(takeName(state, noon).taken, false);
  assert.equal(namesRemaining(state, noon), 0);

  const granted = takeAdGrant(state, noon, 5);
  assert.equal(granted.granted, true);
  const extra = takeName(granted.state, noon);
  assert.equal(extra.taken, true);
  assert.equal(extra.state.namesUsed, 6);
  assert.equal(namesRemaining(extra.state, noon), 0);
  assert.equal(takeName(extra.state, noon).taken, false);
});

test('a failed call or a free not-a-plant gives the name back', () => {
  const held = takeName(null, noon);
  assert.equal(releaseName(held.state).namesUsed, 0);
  assert.equal(releaseName(null).namesUsed, undefined);
});

test('names and ad grants reset on a new UTC month', () => {
  const full: QuotaState = {
    month: '2026-09',
    namesUsed: 5,
    adGrants: 2,
    notPlantFree: 3,
  };
  const next = meterCounts(full, Date.parse('2026-10-01T00:00:00Z'));
  assert.deepEqual(next, { namesUsed: 0, adGrants: 0 });
  assert.equal(takeName(full, Date.parse('2026-10-01T00:00:00Z')).taken, true);
});

test('ad grants stop at the month cap', () => {
  let state: QuotaState | null = null;
  let granted = 0;
  for (let i = 0; i < 7; i++) {
    const taken = takeAdGrant(state, noon, 5);
    state = taken.state;
    if (taken.granted) granted++;
  }
  assert.equal(granted, 5);
});

test('an anonymous account gets one free identification, returned when unused', () => {
  const first = takeAnonymousFree(null);
  assert.equal(first.free, true);
  assert.equal(takeAnonymousFree(first.state).free, false);
  assert.equal(takeAnonymousFree(releaseAnonymousFree(first.state)).free, true);
});

test('the lifetime ceiling asks an anonymous account to sign in', () => {
  const anonymous = { ...limits, dailyCeiling: 15, lifetimeCeiling: 2 };
  let state: QuotaState | null = null;
  state = reserved(reserveCall(state, noon, 'a', anonymous));
  state = reserved(reserveCall(state, noon + 10_000, 'b', anonymous));
  assert.deepEqual(reserveCall(state, noon + 20_000, 'c', anonymous), { refusal: 'sign-in' });
  assert.ok('state' in reserveCall(state, noon + 20_000, 'c', { ...anonymous, lifetimeCeiling: undefined }));
});

test('the shared anonymous slot stops at the day ceiling', () => {
  assert.deepEqual(takeSharedSlot(null, 2), { value: 1, taken: true });
  assert.deepEqual(takeSharedSlot(1, 2), { value: 2, taken: true });
  assert.deepEqual(takeSharedSlot(2, 2), { value: 2, taken: false });
});

test('isPlant uses the probability before the flag', () => {
  assert.equal(isPlant({ is_plant: true, is_plant_probability: 0.2 }, 50), false);
  assert.equal(isPlant({ is_plant: false, is_plant_probability: 0.7 }, 50), true);
  assert.equal(isPlant({ is_plant: false }, 50), false);
  assert.equal(isPlant({ result: { is_plant: { probability: 0.9, binary: false } } }, 50), true);
  assert.equal(isPlant({ result: { is_plant: { binary: false } } }, 50), false);
  assert.equal(isPlant({ suggestions: [] }, 50), true);
  assert.equal(isPlant(null, 50), false);
});

test('hasUnlimitedNames reads server flags and the product list', () => {
  assert.equal(hasUnlimitedNames(null), false);
  assert.equal(hasUnlimitedNames({ credits: 4 }), false);
  assert.equal(hasUnlimitedNames({ 'old version': true }), true);
  assert.equal(hasUnlimitedNames({ 'lifetime subscription': true }), true);
  assert.equal(hasUnlimitedNames({ purchases: ['no_ads', 'search_by_photo'] }), true);
  assert.equal(hasUnlimitedNames({ purchases: { 0: 'store_photos_yearly' } }), true);
  assert.equal(hasUnlimitedNames({ purchases: ['field_guide_monthly'] }), true);
  assert.equal(hasUnlimitedNames({ purchases: { 0: 'field_guide_yearly' } }), true);
  assert.equal(hasUnlimitedNames({ purchases: ['no_ads'] }), false);
});
