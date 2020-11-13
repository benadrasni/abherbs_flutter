import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:abherbs_flutter/utils/utils.dart';

class RemoteConfiguration {
  static RemoteConfig remoteConfig;

  static Future<RemoteConfig> setupRemoteConfig() async {
    remoteConfig = await RemoteConfig.instance;
    // Enable developer mode to relax fetch throttling
    remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: true));
    remoteConfig.setDefaults(<String, dynamic>{
      remoteConfigIPNIServer: 'http://plantsoftheworldonline.org/',
      remoteConfigIPNIServerWithTaxon: 'http://plantsoftheworldonline.org/taxon/urn:lsid:ipni.org:names:',
    });
    await remoteConfig.fetch();
    await remoteConfig.activateFetched();
    return remoteConfig;
  }
}