import { verify, X509Certificate } from 'node:crypto';
import { decodeBase64Url } from './jwt';

/// Apple Root CA - G3. Public certificate, fingerprint pinned below.
export const appleRootCaG3Pem = `-----BEGIN CERTIFICATE-----
MIICQzCCAcmgAwIBAgIILcX8iNLFS5UwCgYIKoZIzj0EAwMwZzEbMBkGA1UEAwwS
QXBwbGUgUm9vdCBDQSAtIEczMSYwJAYDVQQLDB1BcHBsZSBDZXJ0aWZpY2F0aW9u
IEF1dGhvcml0eTETMBEGA1UECgwKQXBwbGUgSW5jLjELMAkGA1UEBhMCVVMwHhcN
MTQwNDMwMTgxOTA2WhcNMzkwNDMwMTgxOTA2WjBnMRswGQYDVQQDDBJBcHBsZSBS
b290IENBIC0gRzMxJjAkBgNVBAsMHUFwcGxlIENlcnRpZmljYXRpb24gQXV0aG9y
aXR5MRMwEQYDVQQKDApBcHBsZSBJbmMuMQswCQYDVQQGEwJVUzB2MBAGByqGSM49
AgEGBSuBBAAiA2IABJjpLz1AcqTtkyJygRMc3RCV8cWjTnHcFBbZDuWmBSp3ZHtf
TjjTuxxEtX/1H7YyYl3J6YRbTzBPEVoA/VhYDKX1DyxNB0cTddqXl5dvMVztK517
IDvYuVTZXpmkOlEKMaNCMEAwHQYDVR0OBBYEFLuw3qFYM4iapIqZ3r6966/ayySr
MA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQDAgEGMAoGCCqGSM49BAMDA2gA
MGUCMQCD6cHEFl4aXTQY2e3v9GwOAEZLuN+yRhHFD/3meoyhpmvOwgPUnPWTxnS4
at+qIxUCMG1mihDK1A3UT82NQz60imOlM27jbdoXt2QfyFMm+YhidDkLF1vLUagM
6BgD56KyKA==
-----END CERTIFICATE-----`;

export const appleRootFingerprint256 =
  '63:34:3A:BF:B8:9A:6A:03:EB:B5:7E:9B:3F:5F:A7:BE:7C:4F:5C:75:6F:30:17:B3:A8:C4:88:C3:65:3E:91:79';

export const appStoreBundleId = 'sk.ab.herbs';

function certificateCurrent(certificate: X509Certificate, now: number): boolean {
  const from = Date.parse(certificate.validFrom);
  const to = Date.parse(certificate.validTo);
  if (!Number.isFinite(from) || !Number.isFinite(to)) return false;
  return from <= now && to >= now;
}

/**
 * Verifies a StoreKit 2 JWS against [rootPem] and returns the payload.
 * The leaf certificate's signature and the chain up to that root must hold.
 */
export function verifyAppleSignedPayload(
  jws: string,
  now: number,
  rootPem = appleRootCaG3Pem,
): Record<string, unknown> | null {
  const parts = jws.split('.');
  if (parts.length !== 3 || parts.some((part) => part.length === 0)) return null;
  let header: { alg?: unknown; x5c?: unknown };
  let payload: unknown;
  try {
    header = JSON.parse(decodeBase64Url(parts[0]).toString('utf8')) as { alg?: unknown; x5c?: unknown };
    payload = JSON.parse(decodeBase64Url(parts[1]).toString('utf8'));
  } catch {
    return null;
  }
  if (header.alg !== 'ES256' || !Array.isArray(header.x5c) || header.x5c.length < 2) return null;
  if (header.x5c.some((entry) => typeof entry !== 'string' || entry.length === 0)) return null;

  let root: X509Certificate;
  let certificates: X509Certificate[];
  try {
    root = new X509Certificate(rootPem);
    certificates = header.x5c.map((entry) => new X509Certificate(Buffer.from(entry, 'base64')));
  } catch {
    return null;
  }
  if (rootPem === appleRootCaG3Pem && root.fingerprint256 !== appleRootFingerprint256) return null;
  if (certificates.some((certificate) => !certificateCurrent(certificate, now))) return null;

  for (let i = 0; i < certificates.length - 1; i++) {
    if (!certificates[i].verify(certificates[i + 1].publicKey)) return null;
  }
  const top = certificates[certificates.length - 1];
  const topIsRoot = top.fingerprint256 === root.fingerprint256;
  if (!topIsRoot && !top.verify(root.publicKey)) return null;

  const signatureOk = verify(
    'sha256',
    Buffer.from(`${parts[0]}.${parts[1]}`),
    { key: certificates[0].publicKey, dsaEncoding: 'ieee-p1363' },
    decodeBase64Url(parts[2]),
  );
  if (!signatureOk || !payload || typeof payload !== 'object') return null;
  return payload as Record<string, unknown>;
}

export type AppleTransaction = {
  productId: string;
  originalTransactionId: string;
  expiresAt: number | null;
  revoked: boolean;
  appAccountToken: string | null;
  environment: string | null;
};

export function appleTransaction(payload: Record<string, unknown>): AppleTransaction | null {
  if (payload.bundleId !== appStoreBundleId) return null;
  const productId = payload.productId;
  const originalTransactionId = payload.originalTransactionId;
  if (typeof productId !== 'string' || !/^[A-Za-z0-9_]{1,64}$/.test(productId)) return null;
  if (typeof originalTransactionId !== 'string' || !/^[0-9]{1,32}$/.test(originalTransactionId)) {
    return null;
  }
  const expiresAt = typeof payload.expiresDate === 'number' ? payload.expiresDate : null;
  const revoked = typeof payload.revocationDate === 'number';
  const appAccountToken = typeof payload.appAccountToken === 'string' ? payload.appAccountToken : null;
  const environment = typeof payload.environment === 'string' ? payload.environment : null;
  return { productId, originalTransactionId, expiresAt, revoked, appAccountToken, environment };
}

export function signedTransactionsFromStatus(body: unknown): string[] {
  if (!body || typeof body !== 'object') return [];
  const data = (body as { data?: unknown }).data;
  if (!Array.isArray(data)) return [];
  const signed: string[] = [];
  for (const group of data) {
    if (!group || typeof group !== 'object') continue;
    const last = (group as { lastTransactions?: unknown }).lastTransactions;
    if (!Array.isArray(last)) continue;
    for (const row of last) {
      if (!row || typeof row !== 'object') continue;
      const info = (row as { signedTransactionInfo?: unknown }).signedTransactionInfo;
      if (typeof info === 'string' && info.length > 0) signed.push(info);
    }
  }
  return signed;
}
