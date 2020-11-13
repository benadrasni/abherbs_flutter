import 'package:abherbs_flutter/feedback.dart';
import 'package:abherbs_flutter/filter/filter_utils.dart';
import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/legend/legend.dart';
import 'package:abherbs_flutter/purchase/enhancements.dart';
import 'package:abherbs_flutter/settings/preferences.dart';
import 'package:abherbs_flutter/settings/settings.dart';
import 'package:abherbs_flutter/signin/authetication.dart';
import 'package:abherbs_flutter/signin/sign_in.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  final firebase_auth.User currentUser;
  final void Function(String) onChangeLanguage;
  final Map<String, String> filter;
  final void Function() settingsCallback;
  AppDrawer(this.currentUser, this.onChangeLanguage, this.filter, this.settingsCallback);

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
  }

  @override
  Widget build(BuildContext context) {
    TextStyle drawerTextStyle = TextStyle(
      fontSize: 16.0,
    );
    Locale myLocale = Localizations.localeOf(context);
    var listItems = <Widget>[];

    listItems.add(Container(
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor,
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          child: ListTile(
            leading: Icon(Icons.person, color: Colors.white,),
            title: Text(
              widget.currentUser?.displayName ?? '',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              widget.currentUser?.email ?? widget.currentUser?.phoneNumber ?? '',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () {},
          ),
        ),
        Container(
          alignment: Alignment(1.0, 1.0),
          child: FlatButton(
            child: Text(
              widget.currentUser == null ? S.of(context).auth_sign_in : S.of(context).auth_sign_out,
              textAlign: TextAlign.end,
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              if (widget.currentUser == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignInScreen(), settings: RouteSettings(name: 'SignIn')),
                ).then((result) {
                  if (mounted) {
                    Navigator.pop(context);
                  }
                });
              } else {
                Auth.signOut(); //logout
                Navigator.pop(context);
              }
            },
          ),
        ),
      ]),
    ));

    listItems.addAll(Preferences.myFilterAttributes.map((attribute) {
      return ListTile(
        leading: getFilterLeading(context, attribute),
        title: Text(
          getFilterText(context, attribute),
          style: drawerTextStyle,
        ),
        subtitle: Text(getFilterSubtitle(context, attribute, _filter[attribute]) ?? ''),
        onTap: () {
          Navigator.pop(context);
          onLeftNavigationTap(context, widget.onChangeLanguage, _filter, attribute);
        },
      );
    }));
    listItems.add(Container(
      height: 5.0,
      color: Theme.of(context).buttonColor,
    ));
    listItems.add(ListTile(
      dense: true,
      title: Text(
        S.of(context).enhancements,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => EnhancementsScreen(widget.onChangeLanguage, widget.filter), settings: RouteSettings(name: 'Enhancements')),
        ).then((result) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      },
    ));
    listItems.add(ListTile(
      dense: true,
      title: Text(
        S.of(context).settings,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SettingsScreen(widget.onChangeLanguage, widget.filter), settings: RouteSettings(name: 'Settings')),
        ).then((result) {
          if (mounted) {
            Navigator.pop(context);
          }
          if (widget.settingsCallback != null) {
            widget.settingsCallback();
          }
        });
      },
    ));
    listItems.add(ListTile(
      dense: true,
      title: Text(
        S.of(context).legend,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LegendScreen(), settings: RouteSettings(name: 'Legend')),
        ).then((result) {
          if (mounted) {
            Navigator.pop(context);
          }
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
          MaterialPageRoute(builder: (context) => FeedbackScreen(widget.onChangeLanguage, widget.filter), settings: RouteSettings(name: 'Feedback')),
        ).then((result) {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      },
    ));
    listItems.add(ListTile(
      dense: true,
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
      dense: true,
      title: Text(
        S.of(context).about,
        style: drawerTextStyle,
      ),
      onTap: () {
        Navigator.pop(context);
        launchURL(webUrl + 'about?lang=' + getLanguageCode(myLocale.languageCode));
      },
    ));

    return Drawer(
        child: ListView(
      children: listItems,
    ));
  }
}
