import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/purchase/purchases.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Offline {
  static bool downloadFinished = false;
  static bool downloadPaused = false;

  static var _httpClient = HttpClient();
  static String _rootPath = '';
  static bool _offline = false;
  static bool _downloadDB = false;
  static String _downloadDBDate = '';
  static List<bool> _keepSynced = [false, false, false, false];

  static void initialize() {
    getApplicationDocumentsDirectory().then((dir) {
      _rootPath = dir.path;
    });

    Prefs.getBoolF(keyOffline, false).then((value) {
      _offline = value;
      if (value) {
        Prefs.getStringF(keyOfflinePlant, '0').then((value) {
          rootReference.child(firebasePlantsToUpdate).child(firebaseAttributeCount).once().then((event) {
            downloadFinished = event.snapshot.value == null || int.parse(value) >= (event.snapshot.value as int);
          });
        }).catchError((_) {
          // deal with previous int shared preferences
          Prefs.getIntF(keyOfflinePlant, 0).then((value) {
            Prefs.setString(keyOfflinePlant, value.toString());
            rootReference.child(firebasePlantsToUpdate).child(firebaseAttributeCount).once().then((event) {
              downloadFinished = event.snapshot.value == null || value >= (event.snapshot.value as int);
            });
          });
          Prefs.getIntF(keyOfflineFamily, 0).then((value) {
            Prefs.setString(keyOfflineFamily, value.toString());
          });
        });
        rootReference.child(firebaseVersions).child(firebaseAttributeLastUpdate).once().then((event) {
          if (event.snapshot.value != null) {
            Prefs.getStringF(keyOfflineDB, '').then((value) {
              _downloadDBDate = event.snapshot.value as String;
              DateTime dbUpdate = DateTime.parse(_downloadDBDate);
              _downloadDB = value.isEmpty || dbUpdate.isAfter(DateTime.parse(value));
            });
          }
        });
      } else {
        downloadFinished = false;
        _downloadDB = false;
      }
    });
  }

  static onChange(bool offline) {
    _offline = offline;
    _downloadDB = offline;
    downloadFinished = false;
    _keepSynced = [false, false, false, false];
  }

  static void finalizeDownloadDB() {
    if (_offline && _keepSynced.reduce((value, item) => value && item)) {
      Prefs.setString(keyOfflineDB, _downloadDBDate);
      _downloadDB = false;
    }
  }

  static Future<void> setKeepSynced(int section, bool value) async {
    if (!value || (_offline && _downloadDB && !_keepSynced[section - 1])) {
      var reference = FirebaseDatabase.instance.ref();
      switch (section) {
        case 1:
          await reference.child(firebaseCounts).keepSynced(value);
          await reference.child(firebaseFamiliesToUpdate).keepSynced(value);
          await reference.child(firebasePlantsToUpdate).keepSynced(value);
          break;
        case 2:
          await reference.child(firebaseLists).keepSynced(value);
          await reference.child(firebasePlantHeaders).keepSynced(value);
          break;
        case 3:
          await reference.child(firebasePlants).keepSynced(value);
          await reference.child(firebaseSynonyms).keepSynced(value);
          var language = await Prefs.getStringListF(keyLanguageAndCountry, ['en', 'US']);
          await reference.child(firebaseTranslations).child(language[0]).keepSynced(value);
          await reference.child(firebaseTranslationsTaxonomy).child(language[0]).keepSynced(value);
          if (language[0] != languageEnglish && language[0] != languageSlovak) {
            await reference.child(firebaseTranslations).child(languageEnglish).keepSynced(value);
            await reference.child(firebaseTranslations).child(language[0] + languageGTSuffix).keepSynced(value);
          }
          break;
        case 4:
          if (Purchases.isSearch()) {
            await reference.child(firebaseAPGIV).keepSynced(value);
            await reference.child(firebaseSearch).child(languageLatin).keepSynced(value);
            var language = await Prefs.getStringListF(keyLanguageAndCountry, ['en', 'US']);
            await reference.child(firebaseSearch).child(language[0]).keepSynced(value);
          }
          break;
      }
      _keepSynced[section - 1] = value;
      if (!Purchases.isSearch()) {
        _keepSynced[3] = value;
      }
      finalizeDownloadDB();
    }
  }

  static void download(
      Function(int, int) onFamilyDownload, Function(int, int) onPlantDownload, Function() onDownloadFinish, Function() onDownloadFail) {
    for (var i = 1; i <= 4; i++) {
      setKeepSynced(i, true);
    }
    Future.wait([downloadFamilies(onFamilyDownload), _downloadPlants(onPlantDownload)]).then((List<bool> results) {
      if (downloadPaused) {
        downloadFinished = false;
      } else {
        downloadFinished = results.reduce((x, y) => x && y);
        if (downloadFinished) {
          onDownloadFinish();
        } else {
          onDownloadFail();
        }
      }
    }).catchError((error) {
      onDownloadFail();
    });
  }

  static Future<bool> downloadFamilies(Function(int, int) onFamilyDownload) async {
    int position = int.parse(await Prefs.getStringF(keyOfflineFamily, '0'));
    int familyTotal = await FirebaseDatabase.instance
        .ref()
        .child(firebaseFamiliesToUpdate)
        .child(firebaseAttributeCount)
        .once()
        .then((event) {
      return event.snapshot.value as int ?? 0;
    });
    while (position < familyTotal) {
      if (await _downloadFamilyIcon(position)) {
        position++;
        Prefs.setString(keyOfflineFamily, position.toString());
        onFamilyDownload(position, familyTotal);
        if (downloadPaused) {
          break;
        }
      } else {
        return false;
      }
    }
    onFamilyDownload(position, familyTotal);
    return true;
  }

  static Future<bool> _downloadFamilyIcon(int position) async {
    String family = await FirebaseDatabase.instance
        .ref()
        .child(firebaseFamiliesToUpdate)
        .child(firebaseAttributeList)
        .child(position.toString())
        .once()
        .then((event) {
      return event.snapshot.value as String;
    });
    if (family != null) {
      var errors = 0;
      await _downloadFile(storageEndpoint + storageFamilies + family + defaultExtension, storageFamilies, family + defaultExtension)
          .catchError((error) {
        errors++;
      });
      return errors == 0;
    } else {
      return false;
    }
  }

  static Future<bool> _downloadPlants(Function(int, int) onPlantDownload) async {
    int position = int.parse(await Prefs.getStringF(keyOfflinePlant, '0'));
    int plantTotal =
        await FirebaseDatabase.instance.ref().child(firebasePlantsToUpdate).child(firebaseAttributeCount).once().then((event) {
      return event.snapshot.value as int ?? 0;
    });
    while (position < plantTotal) {
      if (await _downloadPlantPhotos(position)) {
        position++;
        Prefs.setString(keyOfflinePlant, position.toString());
        onPlantDownload(position, plantTotal);
        if (downloadPaused) {
          break;
        }
      } else {
        return false;
      }
    }

    onPlantDownload(position, plantTotal);
    return true;
  }

  static Future<bool> _downloadPlantPhotos(int position) async {
    late String url;
    String plantName =
        await FirebaseDatabase.instance.ref().child(firebasePlantHeaders).child(position.toString()).once().then((event) {
      url = event.snapshot.value == null ? null : (event.snapshot.value as Map)['url'];
      return event.snapshot.value == null ? null : (event.snapshot.value as Map)['name'];
    });
    if (plantName != null) {
      Plant plant = await FirebaseDatabase.instance.ref().child(firebasePlants).child(plantName).once().then((event) {
        return Plant.fromJson(event.snapshot.key ?? '', event.snapshot.value as Map);
      });
      if (plant != null) {
        var errors = 0;
        var urls = <String>[];
        urls.addAll(plant.photoUrls.map((url) => url as String));
        urls.add(plant.illustrationUrl!);
        if (url != plant.photoUrls[0]) {
          urls.add(url);
        }
        await Future.wait(urls.map((String url) {
          return _downloadFile(storageEndpoint + storagePhotos + url, storagePhotos + url.substring(0, url.lastIndexOf('/')),
                  url.substring(url.lastIndexOf('/') + 1))
              .catchError((error) {
            errors++;
          });
        }));

        return errors == 0;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  static Future<void> delete() async {
    setKeepSynced(1, false);
    setKeepSynced(2, false);
    setKeepSynced(3, false);
    setKeepSynced(4, false);
    if (_rootPath == null) {
      _rootPath = (await getApplicationDocumentsDirectory()).path;
    }
    var familiesDir = Directory('$_rootPath/$storageFamilies');
    if (await familiesDir.exists()) {
      familiesDir.delete(recursive: true);
    }
    var photosDir = Directory('$_rootPath/$storagePhotos');
    if (await photosDir.exists()) {
      photosDir.delete(recursive: true);
    }
    Prefs.setString(keyOfflineFamily, '0');
    Prefs.setString(keyOfflinePlant, '0');
    Prefs.remove(keyOfflineDB);
  }

  static Future<File> _downloadFile(String url, String dir, String filename) async {
    var request = await _httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    if (_rootPath == null) {
      _rootPath = (await getApplicationDocumentsDirectory()).path;
    }
    await Directory('$_rootPath/$dir').create(recursive: true);
    File file = File('$_rootPath/$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future<File> getLocalFile(String filename) async {
    if (_rootPath.isEmpty) {
      _rootPath = (await getApplicationDocumentsDirectory()).path;
    }
    File file = File('$_rootPath/$filename');
    return file;
  }
}
