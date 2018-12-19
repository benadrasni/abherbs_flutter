import 'package:flutter/material.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:abherbs_flutter/settings.dart';

class AppDrawer extends StatefulWidget {
  final void Function(String) onChangeLanguage;
  AppDrawer(this.onChangeLanguage);

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  Widget build(BuildContext context) {
    return new Drawer(
        child: ListView(
      children: <Widget>[
        DrawerHeader(
          child: Text('Drawer Header'),
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
        ),
        ListTile(
          title: Text(S.of(context).settings),
          onTap: () {
            // Update the state of the app
            // ...
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Settings(widget.onChangeLanguage)),
            );
          },
        ),
        ListTile(
          title: Text('Feedback'),
          onTap: () {
            // Update the state of the app
            // ...
            Navigator.pop(context);
          },
        ),
      ],
    ));
  }
}
