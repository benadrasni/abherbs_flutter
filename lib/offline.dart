import 'package:abherbs_flutter/prefs.dart';
import 'package:abherbs_flutter/purchases.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_database/firebase_database.dart';

class Offline {
  static bool downloadFinished = false;

  static void initialize() {
    if (Purchases.isOffline()) {
      FirebaseDatabase.instance.setPersistenceEnabled(true);
      FirebaseDatabase.instance.setPersistenceCacheSizeBytes(firebaseCacheSize);

      setKeepSynced(true);
      Prefs.getBoolF(keyOffline, false).then((value) {
        if (value) {

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
    Prefs.getStringF(keyLanguage, languageEnglish).then((language) {
      reference.child(firebaseTranslations).child(language).keepSynced(value);
      reference.child(firebaseTranslations).child(language + languageGTSuffix).keepSynced(value);
      reference.child(firebaseTranslationsTaxonomy).child(language).keepSynced(value);
      reference.child(firebaseSearch).child(language).keepSynced(value);
    });
  }

  static void download() {
    print('download');
    downloadFinished = true;
  }

  static void delete() {
    setKeepSynced(false);
    print('delete');
  }
}