/** Admin-only count of photographed Latin names that are not in the book. */
export const photoNameTallyPath = 'photo_name_tally';

const illegalKey = /[.#$[\]/]/;

/**
 * `search_photo` key, matching the app: lower case, dots removed.
 * Null when the key is empty or still not a legal Firebase key.
 */
export function photoLookupKey(scientificName: string): string | null {
  const key = scientificName.trim().toLowerCase().replaceAll('.', '');
  if (key.length === 0 || key.length > 200 || illegalKey.test(key)) return null;
  return key;
}

/**
 * A catalog path means the name is already in the book: a species path, or a
 * higher taxon whose path contains `/`. No row means the book does not have it.
 */
export function nameOutsideBook(entry: unknown): boolean {
  if (!entry || typeof entry !== 'object' || Array.isArray(entry)) return true;
  const path = (entry as { path?: unknown }).path;
  return typeof path !== 'string' || path.trim() === '';
}

export function leadingScientificName(suggestions: readonly unknown[]): string | null {
  const first = suggestions[0];
  if (!first || typeof first !== 'object') return null;
  const details = (first as { plant_details?: unknown }).plant_details;
  if (!details || typeof details !== 'object') return null;
  const name = (details as { scientific_name?: unknown }).scientific_name;
  if (typeof name !== 'string') return null;
  const trimmed = name.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export interface NameTally {
  name: string;
  count: number;
}

/** One more photo of [name] this month. Keeps a bare number from an older write. */
export function nextNameTally(current: unknown, name: string): NameTally {
  let count = 0;
  if (typeof current === 'number' && Number.isFinite(current)) {
    count = current;
  } else if (current && typeof current === 'object' && !Array.isArray(current)) {
    const raw = (current as { count?: unknown }).count;
    if (typeof raw === 'number' && Number.isFinite(raw)) count = raw;
  }
  if (count < 0) count = 0;
  return { name, count: Math.floor(count) + 1 };
}
