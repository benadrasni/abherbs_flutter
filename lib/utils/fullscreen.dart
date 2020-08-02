import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullScreenPage extends StatelessWidget {
  final String url;

  FullScreenPage(this.url);

  @override
  Widget build(BuildContext context) {
    var placeholder = Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(),
      Image(
        image: AssetImage('res/images/placeholder.webp'),
      ),
    ]);

    return Scaffold(
      body: PhotoView.customChild(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: getImage(url, placeholder),
        ),
        childSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 4,
      ),
      floatingActionButton: Container(
        height: 50.0,
        width: 50.0,
        child: FittedBox(
          fit: BoxFit.fill,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Icon(Icons.close),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
