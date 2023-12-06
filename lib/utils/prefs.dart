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

/// https://pub.dartlang.org/packages/shared_preferences/
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

/// Export here so the user doesn't have to.
export 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

// ignore: avoid_classes_with_only_static_members
/// The App's Preferences.
class Prefs {
  /// Loads and parses the [SharedPreferences] for this app from disk.
  static Future<SharedPreferences> get instance async =>
      _prefsInstance ??= await SharedPreferences.getInstance();

  static SharedPreferences? _prefsInstance;

  /// In case the developer does not explicitly call the init() function.
  static bool _initCalled = false;

  /// Initialize the SharedPreferences object in the State object's iniState() function.
  static Future<SharedPreferences> init() async {
    _initCalled = true;
    _prefsInstance ??= await instance;
    return _prefsInstance!;
  }

  /// Determine if init was called
  static bool initCalled() => _initCalled;

  /// Indicate if Preferences is ready
  static bool ready() => _prefsInstance != null;

  /// Best to clean up by calling this function in the State object's dispose() function.
  static void dispose() {
    _prefsInstance = null;
  }

  /// Returns all keys in the persistent storage.
  static Set<String> getKeys() {
    assert(_initCalled,
    'Prefs.init() must be called first in an initState() preferably!');
    assert(_prefsInstance != null,
    'Maybe call Prefs.getKeysF() instead. SharedPreferences not ready yet!');
    return _prefsInstance?.getKeys() ?? {};
  }

  /// Returns a Future.
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

  /// Returns true if persistent storage the contains the given [key].
  /// Return null if key is null
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

  /// Returns true if persistent storage the contains the given [key].
  /// Return null if key is null
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

  /// Reads a value of any type from persistent storage.
  /// Return null if key is null.
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

  /// Returns a Future.
  /// Return null if key is null
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

  /// Return false if key is null
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

  /// Returns a Future.
  /// Returns false if key is null.
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

  /// Returns 0 if key is null.
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

  /// Returns a Future.
  /// Returns 0 if key is null.
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

  /// Returns 0 if key is null.
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

  /// Returns a Future.
  /// Returns 0 if key is null.
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

  /// Returns '' if key is null.
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

  /// Returns a Future.
  /// Returns '' if key is null.
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

  /// Returns empty List if key is null.
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

  /// Returns a Future.
  /// Returns empty List if key is null.
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

  /// Saves a boolean [value] to persistent storage in the background.
  /// Returns false if key is null.
  // ignore: avoid_positional_boolean_parameters
  static Future<bool> setBool(String? key, bool? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setBool(key, value);
  }

  /// Saves an integer [value] to persistent storage in the background.
  /// Returns null if key is null.
  static Future<bool> setInt(String? key, int? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setInt(key, value);
  }

  /// Saves a double [value] to persistent storage in the background.
  /// Android doesn't support storing doubles, so it will be stored as a float.
  /// Returns false if key is null.
  static Future<bool> setDouble(String? key, double? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setDouble(key, value);
  }

  /// Saves a string [value] to persistent storage in the background.
  /// Returns false if key is null.
  static Future<bool> setString(String? key, String? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setString(key, value);
  }

  /// Saves a list of strings [value] to persistent storage in the background.
  /// Returns false if key is null.
  static Future<bool> setStringList(String? key, List<String>? value) async {
    if (key == null || value == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.setStringList(key, value);
  }

  /// Fetches the latest values from the host platform.
  /// Use this method to observe modifications that were made in native code
  /// (without using the plugin) while the app is running.
  static Future<void> reload() async {
    final prefs = await instance;
    return prefs.reload();
  }

  /// Removes an entry from persistent storage.
  /// Returns false if key is null.
  static Future<bool> remove(String? key) async {
    if (key == null) {
      return false;
    }
    final prefs = await instance;
    return prefs.remove(key);
  }

  /// Completes with true once the user preferences for the app has been cleared.
  static Future<bool> clear() async {
    final prefs = await instance;
    return prefs.clear();
  }

  /// Sets the prefix that is attached to all keys for all shared preferences.
  /// Return false if called after SharedPreferences was instantiated.
  static bool setPrefix(String prefix, {Set<String>? allowList}) {
    // setPrefix cannot be called after getInstance
    final set = !ready();
    if (set) {
      SharedPreferences.setPrefix(prefix, allowList: allowList);
    }
    return set;
  }
}