import assert from 'node:assert/strict';
import { test } from 'node:test';
import {
  plantIdBody,
  plantIdFinished,
  plantIdLanguage,
  plantIdSuggestions,
  plantIdUrl,
} from './plantid';

test('the v3 request puts details and language on the query', () => {
  assert.equal(
    plantIdUrl('de'),
    'https://plant.id/api/v3/identification?details=common_names,url,description,taxonomy&language=de',
  );
  assert.equal(
    plantIdUrl(undefined),
    'https://plant.id/api/v3/identification?details=common_names,url,description,taxonomy',
  );
  assert.deepEqual(plantIdBody('abc'), { images: ['abc'], similar_images: true });
});

test('language codes follow the v3 list', () => {
  assert.equal(plantIdLanguage('en'), 'en');
  assert.equal(plantIdLanguage('DE'), 'de');
  assert.equal(plantIdLanguage('sk'), undefined);
  assert.equal(plantIdLanguage('zh'), 'zh-hant');
  assert.equal(plantIdLanguage('zh-TW'), 'zh-hant');
  assert.equal(plantIdLanguage('zh_TW'), 'zh-hant');
  assert.equal(plantIdLanguage('zh-CN'), 'zh');
  assert.equal(plantIdLanguage('pt'), 'pt-BR');
  assert.equal(plantIdLanguage('pt-PT'), 'pt-BR');
  assert.equal(plantIdLanguage('ko'), 'ko');
});

test('a completed v3 reply becomes the suggestion shape the app reads', () => {
  const body = {
    status: 'COMPLETED',
    result: {
      is_plant: { probability: 0.99, binary: true, threshold: 0.5 },
      classification: {
        suggestions: [
          {
            id: '872243f84209c0c2',
            name: 'Buddleja davidii',
            probability: 0.9892,
            similar_images: [{ url: 'https://example.test/a.jpg' }],
            details: {
              common_names: ['butterfly bush', ''],
              url: 'https://en.wikipedia.org/wiki/Buddleja_davidii',
              taxonomy: { family: 'Scrophulariaceae', genus: 'Buddleja' },
              description: { value: 'A shrub.', citation: 'Wikipedia' },
              language: 'en',
              entity_id: '872243f84209c0c2',
            },
          },
          { id: 'x', name: '  ', probability: 0.1 },
        ],
      },
    },
  };
  assert.equal(plantIdFinished(body), true);
  assert.deepEqual(plantIdSuggestions(body), [
    {
      id: '872243f84209c0c2',
      probability: 0.9892,
      similar_images: [{ url: 'https://example.test/a.jpg' }],
      plant_details: {
        scientific_name: 'Buddleja davidii',
        common_names: ['butterfly bush'],
        url: 'https://en.wikipedia.org/wiki/Buddleja_davidii',
        taxonomy: { family: 'Scrophulariaceae', genus: 'Buddleja' },
        wiki_description: { value: 'A shrub.', citation: 'Wikipedia' },
      },
    },
  ]);
});

test('an unfinished reply is not a result', () => {
  assert.equal(plantIdFinished({ status: 'PROCESSING' }), false);
  assert.deepEqual(plantIdSuggestions({ status: 'COMPLETED' }), []);
  assert.deepEqual(plantIdSuggestions(null), []);
});
