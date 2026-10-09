import 'package:abherbs_flutter/data/utils.dart';
import 'package:abherbs_flutter/purchase/store_account.dart';
import 'package:abherbs_flutter/purchase/store_proof.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uuid v5 matches the DNS example and the server token', () {
    expect(
      uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
    expect(
      storeAccountToken('user-1'),
      '557118bf-c78c-5e3b-8a47-01153acdb216',
    );
  });

  test('a receipt grants only when the server marks that product active', () {
    expect(
      storeProofGrants(
        StoreProofResult.accepted,
        const {fieldGuideYearly: true},
        fieldGuideYearly,
      ),
      isTrue,
    );
    expect(
      storeProofGrants(
        StoreProofResult.accepted,
        const {fieldGuideYearly: false},
        fieldGuideYearly,
      ),
      isFalse,
    );
    expect(
      storeProofGrants(StoreProofResult.accepted, const {}, fieldGuideYearly),
      isFalse,
    );
    expect(
      storeProofGrants(
        StoreProofResult.rejected,
        const {fieldGuideYearly: true},
        fieldGuideYearly,
      ),
      isFalse,
    );
    expect(
      storeProofGrants(
        StoreProofResult.deferred,
        const {fieldGuideYearly: true},
        fieldGuideYearly,
      ),
      isFalse,
    );
    expect(
      storeProofGrants(
        StoreProofResult.accepted,
        const {fieldGuideYearly: true},
        '',
      ),
      isFalse,
    );
  });
}
