import 'package:abherbs_flutter/signin/authentication.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Ties a rewarded ad to the signed-in account right before it shows. AdMob
/// then calls `admobReward`, which adds the credit; the app only reads it.
Future<void> tieRewardedAd(RewardedAd ad) async {
  final uid = Auth.appUser?.uid;
  if (uid == null) return;
  await ad.setServerSideOptions(ServerSideVerificationOptions(userId: uid));
}
