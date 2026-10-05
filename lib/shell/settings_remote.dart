import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RemoteConfiguration {
  static FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  static Future<FirebaseRemoteConfig> setupRemoteConfig() async {
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: Duration(seconds: 30),
          minimumFetchInterval: Duration(hours: 12)));
      await remoteConfig.setDefaults(<String, dynamic>{
        remoteAdsFrequency: 5,
        remoteMinAndroidBuild: 0,
        remoteMinIosBuild: 0,
        remoteConfigIPNIServer: 'https://powo.science.kew.org/',
        remoteConfigIPNIServerWithTaxon:
            'https://powo.science.kew.org/taxon/urn:lsid:ipni.org:names:',
        remoteConfigSearchByNameVideo: 'https://youtu.be/dapaB7V5Xo0',
        remoteConfigSearchByPhotoVideo: 'https://youtu.be/UaKBnVXavmU'
      });
      await remoteConfig.fetchAndActivate();
    } on PlatformException catch (exception) {
      print(exception);
    } catch (exception) {
      print(
          'Unable to fetch remote config. Cached or default values will be used');
      print(exception);
    }
    return remoteConfig;
  }

  /// One short fetch for the minimum build. A failure returns null and leaves
  /// the last activated value in place. The 12-hour interval used for the
  /// other keys is restored afterwards.
  static Future<int?> fetchMinBuild({required bool android}) async {
    final key = android ? remoteMinAndroidBuild : remoteMinIosBuild;
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 5),
        minimumFetchInterval: Duration.zero,
      ));
      await remoteConfig.fetchAndActivate().timeout(const Duration(seconds: 5));
      return remoteConfig.getInt(key);
    } catch (error) {
      debugPrint('version floor: $error');
      return null;
    } finally {
      try {
        await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 30),
          minimumFetchInterval: const Duration(hours: 12),
        ));
      } catch (error) {
        debugPrint('version floor: $error');
      }
    }
  }

  static int cachedMinBuild({required bool android}) {
    final key = android ? remoteMinAndroidBuild : remoteMinIosBuild;
    try {
      return remoteConfig.getInt(key);
    } catch (error) {
      debugPrint('version floor: $error');
      return 0;
    }
  }
}
