import assert from 'node:assert/strict';
import { test } from 'node:test';
import { storeAccountToken, uuidV5 } from './store_account';

test('uuid v5 matches the DNS example', () => {
  assert.equal(
    uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
    '2ed6657d-e927-568b-95e1-2665a8aea6a2',
  );
});

test('the store account token is a stable uuid', () => {
  const token = storeAccountToken('user-1');
  assert.equal(token, storeAccountToken('user-1'));
  assert.notEqual(token, storeAccountToken('user-2'));
  assert.match(token, /^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/);
});
