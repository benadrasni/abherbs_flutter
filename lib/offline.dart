import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Offline {
  static var httpClient = new HttpClient();
  static bool downloadFinished = false;
  static bool downloadPaused = false;

  static void initialize() {
    if (Purchases.isOffline()) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(firebaseCacheSize);

      setKeepSynced(true);
      Prefs.getBoolF(keyOffline, false).then((value) {
        if (value) {
          Prefs.getIntF(keyOfflinePlant, 0).then((value) {
            FirebaseDatabase.instance.reference().child(firebasePlantsToUpdate).child(firebaseAttributeCount).once().then((DataSnapshot snapshot) {
              downloadFinished = snapshot.value == null || value >= snapshot.value;
            });
          });
        } else {
          downloadFinished = false;
        }
      });
    }
  }

  static void setKeepSynced(bool value) {
    var reference = FirebaseDatabase.instance.reference();
    reference.child(firebaseCounts).keepSynced(value);
    reference.child(firebaseLists).keepSynced(value);
    reference.child(firebasePlantHeaders).keepSynced(value);
    reference.child(firebasePlants).keepSynced(value);
    reference.child(firebaseAPGIV).keepSynced(value);
    reference.child(firebaseSearch).child(languageLatin).keepSynced(value);
    reference.child(firebaseSearch).child(languageEnglish).keepSynced(value);
    reference.child(firebasePlantsToUpdate).keepSynced(value);
    reference.child(firebaseFamiliesToUpdate).keepSynced(value);
    Prefs.getStringF(keyLanguage, languageEnglish).then((language) {
      reference.child(firebaseTranslations).child(language).keepSynced(value);
      reference.child(firebaseTranslations).child(language + languageGTSuffix).keepSynced(value);
      reference.child(firebaseTranslationsTaxonomy).child(language).keepSynced(value);
      reference.child(firebaseSearch).child(language).keepSynced(value);
    });
  }

  static void download(
      Function(int, int) onFamilyDownload, Function(int, int) onPlantDownload, Function() onDownloadFinish, Function() onDownloadFail) {
    Future.wait([downloadFamilies(onFamilyDownload), _downloadPlants(onPlantDownload)]).then((List<bool> results) {
      downloadFinished = results.reduce((x, y) => x && y);
      if (downloadPaused) {
        downloadPaused = false;
      } else if (downloadFinished) {
        onDownloadFinish();
      } else {
        onDownloadFail();
      }
    }).catchError((error) {
      onDownloadFail();
    });
  }

  static Future<bool> downloadFamilies(Function(int, int) onFamilyDownload) async {
    int position = await Prefs.getIntF(keyOfflineFamily, 0);
    int familyTotal = await FirebaseDatabase.instance
        .reference()
        .child(firebaseFamiliesToUpdate)
        .child(firebaseAttributeCount)
        .once()
        .then((DataSnapshot snapshot) {
      return snapshot.value ?? 0;
    });
    while (position < familyTotal) {
      if (await _downloadFamilyIcon(position)) {
        position++;
        Prefs.setInt(keyOfflineFamily, position);
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
        .reference()
        .child(firebaseFamiliesToUpdate)
        .child(firebaseAttributeList)
        .child(position.toString())
        .once()
        .then((DataSnapshot snapshot) {
      return snapshot.value;
    });
    if (family != null) {
      var errors = 0;
      await _downloadFile(storageEndpoit + storageFamilies + family + defaultExtension, storageFamilies, family + defaultExtension)
          .catchError((error) {
        errors++;
      });
      return errors == 0;
    } else {
      return false;
    }
  }

  static Future<bool> _downloadPlants(Function(int, int) onPlantDownload) async {
    int position = await Prefs.getIntF(keyOfflinePlant, 0);
    int plantTotal =
        await FirebaseDatabase.instance.reference().child(firebasePlantsToUpdate).child(firebaseAttributeCount).once().then((DataSnapshot snapshot) {
      return snapshot.value ?? 0;
    });
    while (position < plantTotal) {
      if (await _downloadPlantPhotos(position)) {
        position++;
        Prefs.setInt(keyOfflinePlant, position);
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
    String url;
    String plantName =
        await FirebaseDatabase.instance.reference().child(firebasePlantHeaders).child(position.toString()).once().then((DataSnapshot snapshot) {
      url = snapshot.value == null ? null : snapshot.value['url'];
      return snapshot.value == null ? null : snapshot.value['name'];
    });
    if (plantName != null) {
      Plant plant = await FirebaseDatabase.instance.reference().child(firebasePlants).child(plantName).once().then((DataSnapshot snapshot) {
        return Plant.fromJson(snapshot.key, snapshot.value);
      });
      if (plant != null) {
        var errors = 0;
        var urls = <String>[];
        urls.addAll(plant.photoUrls.map((url) => url as String));
        urls.add(plant.illustrationUrl);
        if (url != plant.photoUrls[0]) {
          urls.add(url);
        }
        await Future.wait(urls.map((String url) {
          return _downloadFile(storageEndpoit + storagePhotos + url, storagePhotos + url.substring(0, url.lastIndexOf('/')),
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

  static void delete() {
    setKeepSynced(false);
    print('delete');
  }

  static Future<File> _downloadFile(String url, String dir, String filename) async {
    var request = await httpClient.getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String rootDir = (await getApplicationDocumentsDirectory()).path;
    await Directory('$rootDir/$dir').create(recursive: true);
    File file = File('$rootDir/$dir$filename');
    await file.writeAsBytes(bytes);
    return file;
  }
}
