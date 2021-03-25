import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:abherbs_flutter/utils/utils.dart';

class RemoteConfiguration {
  static RemoteConfig remoteConfig;

  static Future<RemoteConfig> setupRemoteConfig() async {
    remoteConfig = RemoteConfig.instance;
    remoteConfig.setConfigSettings(RemoteConfigSettings(fetchTimeout:Duration(seconds:30), minimumFetchInterval: Duration(hours: 12)));
    remoteConfig.setDefaults(<String, dynamic>{
      remoteConfigIPNIServer: 'http://plantsoftheworldonline.org/',
      remoteConfigIPNIServerWithTaxon: 'http://plantsoftheworldonline.org/taxon/urn:lsid:ipni.org:names:',
      remoteConfigSearchByNameVideo: 'https://youtu.be/dapaB7V5Xo0',
      remoteConfigSearchByPhotoVideo: 'https://youtu.be/UaKBnVXavmU'
    });
    await remoteConfig.fetch();
    await remoteConfig.activate();
    return remoteConfig;
  }
}