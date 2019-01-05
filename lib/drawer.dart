import 'package:abherbs_flutter/constants.dart';
import 'package:abherbs_flutter/filter/color.dart';
import 'package:abherbs_flutter/filter/distribution.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/filter/habitat.dart';
import 'package:abherbs_flutter/filter/petal.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/main.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final void Function() settingsCallback;
  AppDrawer(this.onChangeLanguage, this.filter, this.settingsCallback);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, String> _filter;

  _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);
  }

  @override
  Widget build(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    var listItems = <Widget>[];
    listItems.addAll(filterAttributes.map((attribute) {
      return ListTile(
        leading: getFilterLeading(context, attribute),
        title: getFilterTitle(context, attribute),
        subtitle: Text(getFilterSubtitle(context, attribute, _filter[attribute]) ?? ""),
        onTap: () {
          Navigator.pop(context);
          var route;
          switch (attribute) {
            case filterColor:
              route = MaterialPageRoute(builder: (context) => Color(widget.onChangeLanguage, _filter));
              break;
            case filterHabitat:
              route = MaterialPageRoute(builder: (context) => Habitat(widget.onChangeLanguage, _filter));
              break;
            case filterPetal:
              route = MaterialPageRoute(builder: (context) => Petal(widget.onChangeLanguage, _filter));
              break;
            case filterDistribution:
              route = MaterialPageRoute(builder: (context) => Distribution(widget.onChangeLanguage, _filter));
              break;
          }
          if (filterRoutes[attribute] != null) {
            Navigator.removeRoute(context, filterRoutes[attribute]);
          }
          filterRoutes[attribute] = route;
          Navigator.push(context, route).then((result) {
            Ads.showBannerAd(this);
          });
        },
      );
    }));
    listItems.add(Divider());
    listItems.add(ListTile(
      title: Text(S.of(context).settings),
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Settings(widget.onChangeLanguage)),
        ).then((result) {
          widget.settingsCallback();
        });
      },
    ));
    listItems.add(ListTile(
      title: Text(S.of(context).feedback),
      onTap: () {
        Navigator.pop(context);
      },
    ));
    listItems.add(ListTile(
      title: Text(S.of(context).help),
      onTap: () {
        Navigator.pop(context);
        _launchURL(webUrl + 'help?lang=' + myLocale.languageCode);
      },
    ));
    listItems.add(ListTile(
      title: Text(S.of(context).about),
      onTap: () {
        Navigator.pop(context);
        _launchURL(webUrl + 'about?lang=' + myLocale.languageCode);
      },
    ));

    return Drawer(
        child: ListView(
      children: listItems,
    ));
  }
}
