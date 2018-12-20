import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/prefs.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  Settings(this.onChangeLanguage);

  @override
  _SettingsState createState() => new _SettingsState();
}

class _SettingsState extends State<Settings> {
  Future<String> _prefLanguage;

  void _changePrefLanguage(String language) {
    setState(() {
      _prefLanguage = Prefs.setString('pref_language', language).then((bool success) {
        widget.onChangeLanguage(language);
        return language == null ? "" : language;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _prefLanguage = Prefs.getStringF(keyPreferredLanguage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textBaseline: TextBaseline.ideographic,
          children: [
            Container(
              child: Text(
                S.of(context).pref_language,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder<String>(
                future: _prefLanguage,
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  String langCode = snapshot.data;
                  if (langCode != null && langCode.isEmpty) {
                    langCode = null;
                  }

                  switch (snapshot.connectionState) {
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    default:
                      return Row(
                        children: [
                          Container(
                            child: DropdownButton<String>(
                              value: langCode,
                              hint: Text(S.of(context).default_language),
                              items: languages.keys.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(languages[value]),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                _changePrefLanguage(newVal);
                              },
                            )),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: langCode == null ? null : () {
                              _changePrefLanguage(null);
                            },
                          ),
                        ]);
                  }
                }),
          ],
        ),
      ),
    );
  }
}

var languages = {
  "ar": "العربية",
  "cs": "Čeština",
  "da": "Dansk",
  "de": "Deutsch",
  "en": "English",
  "es": "Español",
  "et": "Eesti",
  "fa": "فارسی",
  "fr": "Français",
  "hi": "हिन्दी",
  "he": "עברית",
  "hr": "Hrvatski",
  "it": "Italiano",
  "lv": "Latviešu",
  "lt": "Lietuvių",
  "hu": "Magyar",
  "nl": "Nederlands",
  "ja": "日本語",
  "no": "Norsk",
  "pa": "ਪੰਜਾਬੀ",
  "pl": "Polski",
  "pt": "Português",
  "ro": "Română",
  "ru": "Русский",
  "sk": "Slovenčina",
  "sl": "Slovenščina",
  "sr": "Српски / srpski",
  "sv": "Svenska",
  "fi": "Suomi",
  "uk": "Українська"
};
