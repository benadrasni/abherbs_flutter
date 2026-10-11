import 'package:abherbs_flutter/purchase/purchase_reply.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const id = 'field_guide_yearly';

  test('an accepted active product unlocks and stays quiet', () {
    expect(
      storeProofReplyOf(
        const StoreProofOutcome(StoreProofResult.accepted, {id: true}),
        id,
      ),
      StoreProofReply.unlock,
    );
  });

  test(
    'an accepted inactive product shows the failure and does not unlock',
    () {
      expect(
        storeProofReplyOf(
          const StoreProofOutcome(StoreProofResult.accepted, {id: false}),
          id,
        ),
        StoreProofReply.message,
      );
      expect(
        storeProofReplyOf(
          const StoreProofOutcome(StoreProofResult.accepted, {}),
          id,
        ),
        StoreProofReply.message,
      );
    },
  );

  test('a deferred proof stays quiet', () {
    expect(
      storeProofReplyOf(const StoreProofOutcome(StoreProofResult.deferred), id),
      StoreProofReply.nothing,
    );
  });

  test('a rejected proof still shows the failure', () {
    expect(
      storeProofReplyOf(const StoreProofOutcome(StoreProofResult.rejected), id),
      StoreProofReply.message,
    );
  });
}
