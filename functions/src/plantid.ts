/** Plant.id v3 create-identification. https://plant.id/api/v3/identification */
export const plantIdEndpoint = 'https://plant.id/api/v3/identification';

/** Same details v2 requested. v3 names the Wikipedia blurb `description`. */
const plantIdDetails = 'common_names,url,description,taxonomy';

/**
 * Languages Plant.id localizes. `zh` is Simplified and `zh-hant` is Traditional.
 * This app's only Chinese locale is Traditional (`zh_TW`), and the client often
 * sends the language code alone. Portuguese is only offered as `pt-BR`.
 */
const plantIdLanguages = new Set([
  'ar',
  'cs',
  'da',
  'de',
  'en',
  'es',
  'fr',
  'hi',
  'it',
  'ko',
  'nl',
  'pl',
  'sv',
  'tr',
  'zh',
]);

export function plantIdLanguage(raw: string): string | undefined {
  const tag = raw.trim().toLowerCase().replaceAll('_', '-');
  if (tag === 'zh' || tag === 'zh-tw' || tag === 'zh-hk' || tag.startsWith('zh-hant')) {
    return 'zh-hant';
  }
  if (tag === 'zh-cn' || tag.startsWith('zh-hans')) return 'zh';
  if (tag === 'pt' || tag.startsWith('pt-')) return 'pt-BR';
  const base = tag.split('-')[0] ?? tag;
  if (plantIdLanguages.has(base)) return base;
  return undefined;
}

export function plantIdUrl(language: string | undefined): string {
  const details = `details=${plantIdDetails}`;
  if (!language) return `${plantIdEndpoint}?${details}`;
  return `${plantIdEndpoint}?${details}&language=${encodeURIComponent(language)}`;
}

export function plantIdBody(image: string): { images: string[]; similar_images: true } {
  return { images: [image], similar_images: true };
}

export function plantIdFinished(body: unknown): boolean {
  if (!body || typeof body !== 'object') return false;
  return (body as Record<string, unknown>).status === 'COMPLETED';
}

function asRecord(value: unknown): Record<string, unknown> | undefined {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return undefined;
  return value as Record<string, unknown>;
}

function textList(value: unknown): string[] | null {
  if (!Array.isArray(value)) return null;
  const names = value.filter((item): item is string => typeof item === 'string' && item.trim() !== '');
  return names.length > 0 ? names : null;
}

/**
 * v3 keeps suggestions under `result.classification`. The app still reads
 * `plant_details.scientific_name`, `common_names`, `taxonomy`, and `similar_images`.
 */
export function plantIdSuggestions(body: unknown): Record<string, unknown>[] {
  const result = asRecord(asRecord(body)?.result);
  const suggestions = asRecord(result?.classification)?.suggestions;
  if (!Array.isArray(suggestions)) return [];
  const out: Record<string, unknown>[] = [];
  for (const item of suggestions) {
    const suggestion = asRecord(item);
    const name = suggestion?.name;
    if (!suggestion || typeof name !== 'string' || name.trim() === '') continue;
    const details = asRecord(suggestion.details) ?? {};
    out.push({
      id: suggestion.id,
      probability: suggestion.probability,
      similar_images: Array.isArray(suggestion.similar_images) ? suggestion.similar_images : [],
      plant_details: {
        scientific_name: name.trim(),
        common_names: textList(details.common_names),
        url: typeof details.url === 'string' ? details.url : null,
        taxonomy: asRecord(details.taxonomy) ?? null,
        wiki_description: details.description ?? null,
      },
    });
  }
  return out;
}
