import 'dart:async';

import 'package:abherbs_flutter/generated/l10n.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

class PlantDetailEdit extends StatefulWidget {
  final String plantName;
  final String language;
  final String sectionIcon;
  final String sectionLabel;
  final String section;
  final String text;
  final double fontSize;

  PlantDetailEdit(this.plantName, this.language, this.sectionIcon, this.sectionLabel, this.section, this.text, this.fontSize);

  @override
  _PlantDetailEditState createState() => _PlantDetailEditState();
}

class _PlantDetailEditState extends State<PlantDetailEdit> {
  GlobalKey<ScaffoldState> _key;
  TextEditingController _translationController = TextEditingController();

  Future<bool> _savePlantDetail(BuildContext context) async {
    if (_translationController.text.isNotEmpty && _translationController.text.compareTo(widget.text) != 0) {
      await translationsNewReference.child(widget.language).child(widget.plantName).child(widget.section).set(_translationController.text);
    }

    return true;
  }

  _setText() async {
    _translationController.text = await translationsNewReference.child(widget.language).child(widget.plantName).child(widget.section).once().then((event) {
      if (event.snapshot != null && event.snapshot.value != null) {
        return event.snapshot.value;
      }
      return widget.text;
    });
  }

  @override
  void initState() {
    super.initState();
    _key = GlobalKey<ScaffoldState>();
    _setText();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).improve_translation),
      ),
      body: ListView(
        children: [
          Card(
              child: Container(
                margin: EdgeInsets.all(5.0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ListTile(
                title: Text(widget.sectionLabel, style: TextStyle(fontSize: widget.fontSize),),
                leading: widget.sectionIcon.isEmpty ? Icon(Icons.edit) : Image(
                  image: AssetImage(widget.sectionIcon),
                  width: 24.0,
                  height: 24.0,
                ),
              ),
              TextField(
                style: TextStyle(fontSize: widget.fontSize),
                controller: _translationController,
                keyboardType: TextInputType.multiline,
                maxLines: 99,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
          )),
        ],
      ),
      floatingActionButton: Container(
        height: 70.0,
        width: 70.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FloatingActionButton(
            onPressed: () {
              _savePlantDetail(context).then((result) {
                if (result && mounted) {
                  Navigator.of(context).pop(true);
                }
              });
            },
            child: Icon(Icons.save),
          ),
        ),
      ),
    );
  }
}
