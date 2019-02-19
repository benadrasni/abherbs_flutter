import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/enhancements.dart';
import 'package:abherbs_flutter/feedback.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/legend.dart';
import 'package:abherbs_flutter/preferences.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

class AppDrawer extends StatefulWidget {
  final FirebaseUser currentUser;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  final Map<String, String> filter;
  final void Function() settingsCallback;
  AppDrawer(this.currentUser, this.onChangeLanguage, this.onBuyProduct, this.filter, this.settingsCallback);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, String> _filter;

  @override
  void initState() {
    super.initState();
    _filter = new Map<String, String>();
    _filter.addAll(widget.filter);

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle drawerTextStyle = TextStyle(
      fontSize: 16.0,
    );
    Locale myLocale = Localizations.localeOf(context);
    var listItems = <Widget>[];
    listItems.addAll(Preferences.myFilterAttributes.map((attribute) {
      return ListTile(
        leading: getFilterLeading(context, attribute),
        title: Text(
          getFilterText(context, attribute),
          style: drawerTextStyle,
        ),
        subtitle: Text(getFilterSubtitle(context, attribute, _filter[attribute]) ?? ""),
        onTap: () {
          Navigator.pop(context);
          onLeftNavigationTap(context, widget.currentUser, widget.onChangeLanguage, widget.onBuyProduct, _filter, attribute);
        },
      );
    }));
    listItems.add(Container(
      height: 5.0,
      color: Theme.of(context).buttonColor,
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).enhancements,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhancementsScreen(widget.onChangeLanguage, widget.onBuyProduct, widget.filter)),
        ).then((result) {
          Navigator.pop(context);
        });
      },
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).settings,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen(widget.onChangeLanguage, widget.filter)),
        ).then((result) {
          Navigator.pop(context);
          if (widget.settingsCallback != null) {
            widget.settingsCallback();
          }
        });
      },
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).legend,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LegendScreen()),
        ).then((result) {
          Navigator.pop(context);
        });
      },
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).feedback,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FeedbackScreen()),
        ).then((result) {
          Navigator.pop(context);
        });
      },
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).help,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.pop(context);
        launchURL(webUrl + 'help?lang=' + getLanguageCode(myLocale.languageCode));
      },
    ));
    listItems.add(ListTile(
      title: Text(
        S.of(context).about,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.pop(context);
        launchURL(webUrl + 'about?lang=' + getLanguageCode(myLocale.languageCode));
      },
    ));
    if (widget.currentUser != null) {
      listItems.add(ListTile(
        title: Text(
          S.of(context).auth_sign_out,
          style: drawerTextStyle,
        ),
        onTap: () {
          Auth.signOut();//logout
          Navigator.pop(context);
        },
      ));
    } else {
      listItems.add(ListTile(
        title: Text(
          S.of(context).auth_sign_in,
          style: drawerTextStyle,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          ).then((result) {
            Navigator.pop(context);
          });
        },
      ));
    }

    return Drawer(
        child: ListView(
      children: listItems,
    ));
  }
}
