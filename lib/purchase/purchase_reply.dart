enum StoreProofResult { accepted, rejected, deferred }

class StoreProofOutcome {
  final StoreProofResult result;
  final Map<String, bool> products;

  const StoreProofOutcome(this.result, [this.products = const {}]);
}

/// What the purchase listener does with a proof reply.
enum StoreProofReply { unlock, message, nothing }

/// Unlock when this product was accepted and is active. That reply stays
/// quiet. A deferred proof stays quiet and does not unlock. An accepted
/// inactive product, and a rejected proof, ask for the failure message.
StoreProofReply storeProofReplyOf(StoreProofOutcome outcome, String productId) {
  if (outcome.result == StoreProofResult.accepted &&
      outcome.products[productId] == true) {
    return StoreProofReply.unlock;
  }
  if (outcome.result == StoreProofResult.deferred) {
    return StoreProofReply.nothing;
  }
  return StoreProofReply.message;
}
