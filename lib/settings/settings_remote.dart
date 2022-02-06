import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/services.dart';

class RemoteConfiguration {
  static FirebaseRemoteConfig remoteConfig;

  static Future<FirebaseRemoteConfig> setupRemoteConfig() async {
    remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
          fetchTimeout: Duration(seconds: 30),
          minimumFetchInterval: Duration(hours: 12)));
      await remoteConfig.setDefaults(<String, dynamic>{
        remoteAdsFrequency: 5,
        remoteConfigIPNIServer: 'http://plantsoftheworldonline.org/',
        remoteConfigIPNIServerWithTaxon: 'http://plantsoftheworldonline.org/taxon/urn:lsid:ipni.org:names:',
        remoteConfigSearchByNameVideo: 'https://youtu.be/dapaB7V5Xo0',
        remoteConfigSearchByPhotoVideo: 'https://youtu.be/UaKBnVXavmU'
      });
      await remoteConfig.fetchAndActivate();
    } on PlatformException catch (exception) {
      // Fetch exception.
      print(exception);
    } catch (exception) {
      print('Unable to fetch remote config. Cached or default values will be used');
      print(exception);
    }
    return remoteConfig;
  }
}