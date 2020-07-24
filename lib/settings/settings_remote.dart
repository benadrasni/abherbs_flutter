import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:abherbs_flutter/utils/utils.dart';

class RemoteConfiguration {
  static Future<RemoteConfig> setupRemoteConfig() async {
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    // Enable developer mode to relax fetch throttling
    remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: true));
    remoteConfig.setDefaults(<String, dynamic>{
      remoteConfigIPNIServer: 'http://plantsoftheworldonline.org/',
    });
    return remoteConfig;
  }
}