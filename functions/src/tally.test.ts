import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  leadingScientificName,
  nameOutsideBook,
  nextNameTally,
  photoLookupKey,
} from './tally';

test('the photo key matches the app lookup', () => {
  assert.equal(photoLookupKey('  Buddleja davidii '), 'buddleja davidii');
  assert.equal(photoLookupKey('Hieracium murorum subsp. murorum'), 'hieracium murorum subsp murorum');
  assert.equal(photoLookupKey('Mentha × piperita'), 'mentha × piperita');
  assert.equal(photoLookupKey(''), null);
  assert.equal(photoLookupKey('...'), null);
  assert.equal(photoLookupKey('Bad/name'), null);
  assert.equal(photoLookupKey('bad#name'), null);
  assert.equal(photoLookupKey('a'.repeat(201)), null);
});

test('only a missing catalog path is outside the book', () => {
  assert.equal(nameOutsideBook(null), true);
  assert.equal(nameOutsideBook({}), true);
  assert.equal(nameOutsideBook({ path: '  ' }), true);
  assert.equal(nameOutsideBook({ count: 1, path: 'Bellis perennis' }), false);
  assert.equal(nameOutsideBook({ count: 12, path: 'Asteraceae/Bellis/list' }), false);
});

test('the tally keeps the Latin name and increments the month count', () => {
  assert.deepEqual(nextNameTally(null, 'Tanacetum corymbosum'), {
    name: 'Tanacetum corymbosum',
    count: 1,
  });
  assert.deepEqual(nextNameTally({ name: 'Tanacetum corymbosum', count: 3 }, 'Tanacetum corymbosum'), {
    name: 'Tanacetum corymbosum',
    count: 4,
  });
  assert.deepEqual(nextNameTally(2, 'Tanacetum corymbosum'), {
    name: 'Tanacetum corymbosum',
    count: 3,
  });
  assert.equal(nextNameTally({ count: -5 }, 'Tanacetum corymbosum').count, 1);
});

test('only the leading scientific name is counted', () => {
  assert.equal(
    leadingScientificName([
      { plant_details: { scientific_name: ' Tanacetum corymbosum ' } },
      { plant_details: { scientific_name: 'Bellis perennis' } },
    ]),
    'Tanacetum corymbosum',
  );
  assert.equal(leadingScientificName([]), null);
  assert.equal(leadingScientificName([{ plant_details: { scientific_name: '  ' } }]), null);
});
