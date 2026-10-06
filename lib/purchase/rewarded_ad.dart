import 'package:abherbs_flutter/person/authentication.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

Future<void> tieRewardedAd(RewardedAd ad) async {
  final uid = Auth.appUser?.uid;
  if (uid == null) return;
  await ad.setServerSideOptions(ServerSideVerificationOptions(userId: uid));
}
