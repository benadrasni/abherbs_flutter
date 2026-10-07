import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  planGrant,
  productsFromWrites,
  purchaseActive,
  type EntitlementRow,
  type VerifiedPurchase,
} from './entitlements';
import { grantPurchase, releaseStorePurchases, type EntitlementDb } from './store_handlers';
import { storeAccountToken } from './store_account';

const now = Date.parse('2026-10-06T12:00:00Z');
const uid = 'user-1';
const token = storeAccountToken(uid);

function yearly(overrides: Partial<VerifiedPurchase> = {}): VerifiedPurchase {
  return {
    store: 'app_store',
    productId: 'field_guide_yearly',
    token: '1000',
    expiresAt: now + 86_400_000,
    revoked: false,
    accountToken: token,
    environment: 'Production',
    subscription: true,
    ...overrides,
  };
}

test('a future expiry is active and a revocation is not', () => {
  assert.equal(purchaseActive({ revoked: false, expiresAt: now + 1 }, now), true);
  assert.equal(purchaseActive({ revoked: false, expiresAt: now }, now), false);
  assert.equal(purchaseActive({ revoked: true, expiresAt: now + 1 }, now), false);
  assert.equal(purchaseActive({ revoked: false, expiresAt: null }, now), true);
});

test('a checked subscription is written on the account and the other plan is cleared', () => {
  const monthly: EntitlementRow = {
    active: true,
    store: 'app_store',
    originalId: 'app_store_1000',
    updatedAt: now - 1,
  };
  const plan = planGrant({
    uid,
    now,
    purchase: yearly(),
    existing: null,
    previousOwnerExists: false,
    products: { field_guide_monthly: monthly },
  });
  assert.equal('error' in plan, false);
  if ('error' in plan) return;
  const products = productsFromWrites(plan.writes);
  assert.equal(products.field_guide_yearly, true);
  assert.equal(products.field_guide_monthly, false);
  assert.equal(plan.writes.some((write) => write.path === `store_accounts/${token}`), true);
});

test('a receipt named for another account is refused until that account is gone', () => {
  const foreign = storeAccountToken('user-2');
  const refused = planGrant({
    uid,
    now,
    purchase: yearly({ accountToken: foreign }),
    existing: null,
    previousOwnerExists: false,
    products: {},
  });
  assert.deepEqual(refused, { error: 'other-account' });

  const expired = planGrant({
    uid,
    now,
    purchase: yearly({ accountToken: foreign, expiresAt: now - 1 }),
    existing: {
      uid,
      store: 'app_store',
      productId: 'field_guide_yearly',
      token: '1000',
      accountToken: token,
      expiresAt: now + 1,
      environment: 'Production',
      subscription: true,
      active: true,
      updatedAt: now,
    },
    previousOwnerExists: false,
    products: {
      field_guide_yearly: {
        active: true,
        store: 'app_store',
        originalId: 'app_store_1000',
        updatedAt: now,
      },
    },
  });
  assert.equal('error' in expired, false);
  if ('error' in expired) return;
  assert.equal(productsFromWrites(expired.writes).field_guide_yearly, false);
  assert.equal(expired.writes.some((write) => write.path.startsWith('store_accounts/')), false);

  const rebound = planGrant({
    uid: 'user-2',
    now,
    purchase: yearly({ accountToken: token }),
    existing: {
      uid,
      store: 'app_store',
      productId: 'field_guide_yearly',
      token: '1000',
      accountToken: token,
      expiresAt: now + 1,
      environment: 'Production',
      subscription: true,
      active: true,
      updatedAt: now,
    },
    previousOwnerExists: false,
    products: {},
  });
  assert.equal('error' in rebound, false);
  if ('error' in rebound) return;
  assert.equal(productsFromWrites(rebound.writes).field_guide_yearly, true);
  assert.equal(
    rebound.writes.some((write) => write.path === `users/${uid}/entitlements/products/field_guide_yearly` && write.value == null),
    true,
  );
});

test('a receipt owned by a live account is refused', () => {
  const plan = planGrant({
    uid: 'user-2',
    now,
    purchase: yearly({ accountToken: storeAccountToken('user-2') }),
    existing: {
      uid,
      store: 'app_store',
      productId: 'field_guide_yearly',
      token: '1000',
      accountToken: token,
      expiresAt: now + 1,
      environment: 'Production',
      subscription: true,
      active: true,
      updatedAt: now,
    },
    previousOwnerExists: true,
    products: {},
  });
  assert.deepEqual(plan, { error: 'other-account' });
});

test('an expired receipt does not clear a different purchase of the same product', () => {
  const plan = planGrant({
    uid,
    now,
    purchase: yearly({ token: '2000', expiresAt: now - 1, accountToken: token }),
    existing: null,
    previousOwnerExists: false,
    products: {
      field_guide_yearly: {
        active: true,
        store: 'play',
        originalId: 'play_other',
        updatedAt: now,
      },
    },
  });
  assert.equal('error' in plan, false);
  if ('error' in plan) return;
  assert.equal(productsFromWrites(plan.writes).field_guide_yearly, undefined);
});

function putPath(root: Record<string, unknown>, path: string, value: unknown): void {
  const parts = path.split('/');
  let cursor = root;
  for (const part of parts.slice(0, -1)) {
    const next = cursor[part];
    if (!next || typeof next !== 'object') cursor[part] = {};
    cursor = cursor[part] as Record<string, unknown>;
  }
  cursor[parts[parts.length - 1]] = value;
}

function memoryDb(): EntitlementDb & { tree: Record<string, unknown> } {
  const tree: Record<string, unknown> = {};
  const read = (path: string): unknown => {
    let cursor: unknown = tree;
    for (const part of path.split('/')) {
      if (!cursor || typeof cursor !== 'object' || !(part in cursor)) return null;
      cursor = (cursor as Record<string, unknown>)[part];
    }
    return cursor ?? null;
  };
  return {
    tree,
    async get(path) {
      return read(path);
    },
    async set(path, value) {
      putPath(tree, path, value);
    },
    async remove(path) {
      const parts = path.split('/');
      let cursor: unknown = tree;
      for (const part of parts.slice(0, -1)) {
        if (!cursor || typeof cursor !== 'object') return;
        cursor = (cursor as Record<string, unknown>)[part];
      }
      if (cursor && typeof cursor === 'object') {
        delete (cursor as Record<string, unknown>)[parts[parts.length - 1]];
      }
    },
    async authExists(id) {
      return id === uid;
    },
  };
}

test('granting then releasing removes the proof and the account record', async () => {
  const db = memoryDb();
  const granted = await grantPurchase(db, uid, yearly(), now);
  assert.equal('products' in granted && granted.products.field_guide_yearly, true);
  const proofs = db.tree.purchase_proofs as Record<string, unknown>;
  assert.ok(proofs.app_store_1000);
  await releaseStorePurchases(db, uid);
  assert.equal(proofs.app_store_1000, undefined);
  const account = (db.tree.users as Record<string, Record<string, unknown>> | undefined)?.[uid];
  assert.equal(account?.entitlements, undefined);
  const accounts = db.tree.store_accounts as Record<string, unknown> | undefined;
  assert.equal(accounts?.[token], undefined);
});
