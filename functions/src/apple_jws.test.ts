import assert from 'node:assert/strict';
import { createPrivateKey, X509Certificate } from 'node:crypto';
import { test } from 'node:test';
import { appleRootCaG3Pem, appleRootFingerprint256, appleTransaction, verifyAppleSignedPayload } from './apple_jws';
import { signedJwt } from './jwt';

const rootPem = `-----BEGIN CERTIFICATE-----
MIIBfTCCASKgAwIBAgITXDGXza4UD98TK+dwingaXYoNejAKBggqhkjOPQQDAjAU
MRIwEAYDVQQDDAlUZXN0IFJvb3QwHhcNMjYxMDA2MjA0MTU4WhcNMzYxMDAzMjA0
MTU4WjAUMRIwEAYDVQQDDAlUZXN0IFJvb3QwWTATBgcqhkjOPQIBBggqhkjOPQMB
BwNCAAT8S+kriavkgeF4dMmBU77BkGArpeoYmcPJa2Gn7BrExCtUpLs9tIfoJvBW
lu0ua5XFuZ7V4vjV62jI9w8SxP7Ro1MwUTAdBgNVHQ4EFgQUjzd2nKzvCYmQ0j2J
4adrv8Hfb1gwHwYDVR0jBBgwFoAUjzd2nKzvCYmQ0j2J4adrv8Hfb1gwDwYDVR0T
AQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBGAiEA+TwJ0BpX48IX6iANOVDfCrJb
YvKKQe5/O7Di+T9YuxwCIQDM5GTeONG7bsSyOX8eExPfz2Cq3VxYpHQ5LdoFKh2n
aQ==
-----END CERTIFICATE-----`;

const leafPem = `-----BEGIN CERTIFICATE-----
MIIBazCCARKgAwIBAgIUZcscLtnVYfEVrnkWoPdI0JS1nOYwCgYIKoZIzj0EAwIw
FDESMBAGA1UEAwwJVGVzdCBSb290MB4XDTI2MTAwNjIwNDE1OFoXDTM2MTAwMzIw
NDE1OFowFDESMBAGA1UEAwwJVGVzdCBMZWFmMFkwEwYHKoZIzj0CAQYIKoZIzj0D
AQcDQgAE3qgHAS6V9jpFs0DmTS0NDjhN98s883PzHxNc9hYl2/Ab3xEtWLntXXSi
kM6495+ottq2v1dwq0npnKvsJDkAq6NCMEAwHQYDVR0OBBYEFOXo2rnQP+rtNLCu
a4feTBjiwM2BMB8GA1UdIwQYMBaAFI83dpys7wmJkNI9ieGna7/B329YMAoGCCqG
SM49BAMCA0cAMEQCIB1JX0ChAjPNoeDCVtFxA3+/5Tb7AMVndeZXdUMnq5XsAiAq
TRCtY7zgqF1NU9KjFHFNOgPKy4CsreQU/zVPHMJ+kg==
-----END CERTIFICATE-----`;

const leafKey = `-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKs6TNTARlvtLVb5VC9ObF4+eMGn0Smo54GdZsINHTA3oAoGCCqGSM49
AwEHoUQDQgAE3qgHAS6V9jpFs0DmTS0NDjhN98s883PzHxNc9hYl2/Ab3xEtWLnt
XXSikM6495+ottq2v1dwq0npnKvsJDkAqw==
-----END EC PRIVATE KEY-----`;

function jws(payload: Record<string, unknown>): string {
  const leaf = new X509Certificate(leafPem).raw.toString('base64');
  const root = new X509Certificate(rootPem).raw.toString('base64');
  return signedJwt({ alg: 'ES256', x5c: [leaf, root] } as unknown as Record<string, string>, payload, leafKey, 'ES256');
}

test('the pinned Apple root matches its published fingerprint', () => {
  assert.equal(new X509Certificate(appleRootCaG3Pem).fingerprint256, appleRootFingerprint256);
});

test('a chained StoreKit transaction verifies and a changed payload does not', () => {
  const now = Date.parse('2026-10-06T21:00:00Z');
  const signed = jws({
    bundleId: 'sk.ab.herbs',
    productId: 'field_guide_yearly',
    originalTransactionId: '1000',
    expiresDate: now + 1000,
    environment: 'Sandbox',
  });
  const payload = verifyAppleSignedPayload(signed, now, rootPem);
  assert.ok(payload);
  assert.equal(appleTransaction(payload)?.productId, 'field_guide_yearly');
  assert.equal(appleTransaction({ ...payload, bundleId: 'other.app' }), null);

  const parts = signed.split('.');
  const tampered = `${parts[0]}.${Buffer.from('{"bundleId":"sk.ab.herbs"}').toString('base64url')}.${parts[2]}`;
  assert.equal(verifyAppleSignedPayload(tampered, now, rootPem), null);
  assert.equal(createPrivateKey(leafKey).asymmetricKeyType, 'ec');
});
