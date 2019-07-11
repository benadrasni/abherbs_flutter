import 'package:abherbs_flutter/utils/utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/utils/prefs.dart';
import 'package:abherbs_flutter/settings/setting_utils.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

final countsReference = FirebaseDatabase.instance.reference().child(firebaseCounts);

class SettingPrefLanguage extends StatefulWidget {
  @override
  _SettingPrefLanguageState createState() => _SettingPrefLanguageState();
}

class _SettingPrefLanguageState extends State<SettingPrefLanguage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: new Text(S.of(context).pref_language),
      ),
      body: ListView.builder(
        itemCount: languages.length,
        itemBuilder: (context, index) {
          String key = languages.keys.elementAt(index);
          return ListTile(
            title: Text(languages[key]),
            onTap: () {
              Prefs.setString(keyPreferredLanguage, key).then((result) {
                if (mounted) {
                  Navigator.pop(context);
                }
              });
            },
          );
        },
      ),
    );
  }
}
