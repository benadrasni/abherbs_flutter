import 'dart:async';
import 'dart:io';

import 'package:abherbs_flutter/ads.dart';
import 'package:abherbs_flutter/generated/i18n.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class SearchPhoto extends StatefulWidget {
  final FirebaseUser currentUser;
  final Locale myLocale;
  final void Function(String) onChangeLanguage;
  final void Function(PurchasedItem) onBuyProduct;
  SearchPhoto(this.currentUser, this.myLocale, this.onChangeLanguage, this.onBuyProduct);

  @override
  _SearchPhotoState createState() => _SearchPhotoState();
}

class _SearchPhotoState extends State<SearchPhoto> {
  GlobalKey<ScaffoldState> _key;
  File _image;
  List<Label> _labels;

  Future<void> _getImage(GlobalKey<ScaffoldState> _key, ImageSource source) async {
    var image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(image);
      final CloudLabelDetector labelDetector = FirebaseVision.instance.cloudLabelDetector();
      final List<Label> labels = await labelDetector.detectInImage(visionImage);
      setState(() {
        _image = image;
        _labels = labels;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _key = new GlobalKey<ScaffoldState>();

    Ads.hideBannerAd();
  }

  @override
  Widget build(BuildContext context) {
    double mapWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(S.of(context).product_photo_search_title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add_a_photo),
            onPressed: () {
              _getImage(_key, ImageSource.camera);
            },
          ),
          IconButton(
            icon: Icon(Icons.add_photo_alternate),
            onPressed: () {
              _getImage(_key, ImageSource.gallery);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Card(
            child: Container(
              padding: EdgeInsets.all(5.0),
              width: mapWidth,
              height: mapWidth,
              child: _image == null
                  ? Center(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        GestureDetector(
                          child: Icon(Icons.add_a_photo, color: Theme.of(context).buttonColor, size: 80.0),
                          onTap: () {
                            _getImage(_key, ImageSource.camera);
                          },
                        ),
                        SizedBox(width: 80.0),
                        GestureDetector(
                          child: Icon(Icons.add_photo_alternate, color: Theme.of(context).buttonColor, size: 80.0),
                          onTap: () {
                            _getImage(_key, ImageSource.gallery);
                          },
                        )
                      ]),
                    )
                  : Image.file(_image, fit: BoxFit.cover, width: mapWidth, height: mapWidth),
            ),
          ),
          Card(
              child: Padding(
            padding: EdgeInsets.all(10.0),
            child: _labels == null ? Text(S.of(context).photo_search_note, style: TextStyle(fontSize: 18.0),) :
            Column(children: _labels.map((label) {
              return ListTile(title: Text(label.label), trailing: Text(label.confidence.toString()),);
            }).toList()),
          )),
        ],
      ),
    );
  }
}
