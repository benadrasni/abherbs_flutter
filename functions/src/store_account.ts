import { createHash } from 'node:crypto';

/// RFC 4122 DNS namespace. The account token is UUID v5 of `sk.ab.herbs:{uid}`.
const dnsNamespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

function uuidBytes(uuid: string): Buffer {
  const hex = uuid.replace(/-/g, '');
  if (!/^[0-9a-f]{32}$/i.test(hex)) throw new Error('uuid');
  return Buffer.from(hex, 'hex');
}

export function uuidV5(namespace: string, name: string): string {
  const hash = createHash('sha1').update(uuidBytes(namespace)).update(name, 'utf8').digest();
  const bytes = Buffer.from(hash.subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString('hex');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/// Stable token stored with Apple as appAccountToken and with Play as the
/// obfuscated account id. One lookup finds the Firebase user.
export function storeAccountToken(uid: string): string {
  return uuidV5(dnsNamespace, `sk.ab.herbs:${uid}`);
}
