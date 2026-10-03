///
/// Copyright (C) 2018 Andrious Solutions Ltd.
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
///    http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///
///          Created  05 Jun 2018
///
/// Github: https://github.com/AndriousSolutions/prefs
///
library prefs;

import 'dart:async' show Future;

import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// Export here so the user doesn't have to.
export 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

// ignore: avoid_classes_with_only_static_members
class Prefs {
  static Future<SharedPreferences> get instance async =>
      _prefsInstance ??= await SharedPreferences.getInstance();

  static SharedPreferences? _prefsInstance;

  static bool _initCalled = false;

  static Future<SharedPreferences> init() async {
    _initCalled = true;
    _prefsInstance ??= await instance;
    return _prefsInstance!;
  }

  static bool initCalled() => _initCalled;

  static bool ready() => _prefsInstance != null;

  static void dispose() {
    _prefsInstance = null;
  }

  static Set<String> getKeys() {
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getKeysF() instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getKeys() ?? {};
  }

  static Future<Set<String>> getKeysF() async {
    Set<String> value;
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getKeys();
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getKeys();
    }
    return value;
  }

  static bool containsKey(String? key) {
    if (key == null) {
      return false;
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.containsKeyF() instead. SharedPreferences not ready yet!');
    return _prefsInstance?.containsKey(key) ?? false;
  }

  static Future<bool> containsKeyF(String? key) async {
    bool contains;
    if (key == null) {
      return false;
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      contains = prefs.containsKey(key);
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      contains = _prefsInstance!.containsKey(key);
    }
    return contains;
  }

  static Object? get(String? key) {
    if (key == null) {
      return null;
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getF(key) instead. SharedPreferences not ready yet!');
    return _prefsInstance?.get(key);
  }

  static Future<Object?> getF(String? key) async {
    Object? value;
    if (key == null) {
      return null;
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.get(key);
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = get(key);
    }
    return value;
  }

  // ignore: avoid_positional_boolean_parameters
  static bool getBool(String? key, [bool? defValue]) {
    if (key == null) {
      return false;
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getBoolF(key) instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getBool(key) ?? defValue ?? false;
  }

  // ignore: avoid_positional_boolean_parameters
  static Future<bool> getBoolF(String? key, [bool? defValue]) async {
    if (key == null) {
      return false;
    }
    bool value;
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getBool(key) ?? defValue ?? false;
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getBool(key, defValue);
    }
    return value;
  }

  static int getInt(String? key, [int? defValue]) {
    if (key == null) {
      return 0;
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getIntF(key) instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getInt(key) ?? defValue ?? 0;
  }

  static Future<int> getIntF(String? key, [int? defValue]) async {
    int value;
    if (key == null) {
      return 0;
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getInt(key) ?? defValue ?? 0;
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getInt(key, defValue);
    }
    return value;
  }

  static double getDouble(String? key, [double? defValue]) {
    if (key == null) {
      return 0;
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getDoubleF(key) instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getDouble(key) ?? defValue ?? 0.0;
  }

  static Future<double> getDoubleF(String? key, [double? defValue]) async {
    double value;
    if (key == null) {
      return 0;
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getDouble(key) ?? defValue ?? 0.0;
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getDouble(key, defValue);
    }
    return value;
  }

  static String getString(String? key, [String? defValue]) {
    if (key == null) {
      return '';
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getStringF(key)instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getString(key) ?? defValue ?? '';
  }

  static Future<String> getStringF(String? key, [String? defValue]) async {
    String value;
    if (key == null) {
      return '';
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getString(key) ?? defValue ?? '';
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getString(key, defValue);
    }
    return value;
  }

  static List<String> getStringList(String? key, [List<String>? defValue]) {
    if (key == null) {
      return [''];
    }
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getStringListF(key) instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getStringList(key) ?? defValue ?? [''];
  }

  static Future<List<String>> getStringListF(String? key,
      [List<String>? defValue]) async {
    List<String> value;
    if (key == null) {
      return [''];
    }
    if (_prefsInstance == null) {
      final prefs = await instance;
      value = prefs.getStringList(key) ?? defValue ?? [''];
    } else {
      // SharedPreferences is available. Ignore init() function.
      _initCalled = true;
      value = getStringList(key, defValue);
    }
    return value;
  }

  // ignore: avoid_positional_boolean_parameters
  static Future<bool> setBool(String? key, bool? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setBool(key, value);
  }

  static Future<bool> setInt(String? key, int? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setInt(key, value);
  }

  /// Android doesn't support storing doubles, so it will be stored as a float.
  static Future<bool> setDouble(String? key, double? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setDouble(key, value);
  }

  static Future<bool> setString(String? key, String? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setString(key, value);
  }

  static Future<bool> setStringList(String? key, List<String>? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setStringList(key, value);
  }

  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  static Future<void> reload() async {
    final prefs = await instance;
    return prefs.reload();
  }

  static Future<bool> remove(String? key) async {
    if (key == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.remove(key);
  }

  static Future<bool> clear() async {
    final prefs = await instance;
    return prefs.clear();
  }

  static bool setPrefix(String prefix, {Set<String>? allowList}) {
    // setPrefix cannot be called after getInstance
    final set = !ready();
    if (set) {
      SharedPreferences.setPrefix(prefix, allowList: allowList);
    }
    return set;
  }
}