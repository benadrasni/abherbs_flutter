import { createPrivateKey, sign } from 'node:crypto';

export function base64Url(input: Buffer | string): string {
  const buffer = typeof input === 'string' ? Buffer.from(input) : input;
  return buffer.toString('base64url');
}

export function decodeBase64Url(input: string): Buffer {
  return Buffer.from(input, 'base64url');
}

/// Compact JWT. ES256 signatures are raw R||S, which is what Apple expects.
export function signedJwt(
  header: Record<string, string>,
  payload: Record<string, unknown>,
  privateKeyPem: string,
  algorithm: 'RS256' | 'ES256',
): string {
  const encoded = `${base64Url(JSON.stringify(header))}.${base64Url(JSON.stringify(payload))}`;
  const signature = sign(algorithm === 'RS256' ? 'RSA-SHA256' : 'sha256', Buffer.from(encoded), {
    key: createPrivateKey(privateKeyPem),
    dsaEncoding: 'ieee-p1363',
  });
  return `${encoded}.${base64Url(signature)}`;
}
