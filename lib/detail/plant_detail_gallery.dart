import 'package:abherbs_flutter/detail/plant_detail_info.dart';
import 'package:abherbs_flutter/entity/plant.dart';
import 'package:abherbs_flutter/utils/fullscreen.dart';
import 'package:abherbs_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

List<YoutubePlayerController> controllers = [];

Widget getGallery(BuildContext context, Plant plant) {
  List<Widget> cards = [];

  cards.add(Card(
    color: const Color(0xFFF4EFE4),
    child: _getImageButton(
      context,
      storagePhotos + plant.illustrationUrl!,
      aspectRatio: 2 / 3,
    ),
  ));

  if (plant.videoUrls.length > 0) {
    cards.addAll(plant.videoUrls.map((url) {
      controllers.add(YoutubePlayerController.fromVideoId(
        videoId: YoutubePlayerController.convertUrlToId(url)!,
        autoPlay: false,
        params: YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          enableCaption: false,
        ),
      ));

      return Card(
        child: Stack(children: [
          YoutubePlayer(
            controller: controllers.last,
            aspectRatio: 16 / 9,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: TextButton(
              style: TextButton.styleFrom(
                minimumSize: Size(100, 10),
              ),
              child: Text(''),
              onPressed: () {
                launchURL(url);
              },
            ),
          ),
        ]),
      );
    }));
  }

  cards.addAll(plant.photoUrls.map((url) {
    return Card(
      child: _getImageButton(context, storagePhotos + url),
    );
  }));

  if (plant.sourceUrls.isNotEmpty) {
    cards.add(Card(
      child: Container(
        padding: EdgeInsets.all(5.0),
        child: PlantSourcesSection(plant.sourceUrls),
      ),
    ));
  }

  return ListView(
    shrinkWrap: true,
    padding: EdgeInsets.all(5.0),
    children: cards,
  );
}

List<YoutubePlayerController> getYoutubeControllers() {
  return controllers;
}

Widget _getImageButton(BuildContext context, String url, {double aspectRatio = 1}) {
  double screenWidth = MediaQuery.of(context).size.width - 20;
  double height = screenWidth / aspectRatio;
  var placeholder = Stack(alignment: Alignment.center, children: [
    CircularProgressIndicator(),
    Image(
      image: AssetImage('res/images/placeholder.webp'),
    ),
  ]);
  return GestureDetector(
    child: Container(
      padding: EdgeInsets.all(5.0),
      child: getImage(url, placeholder, width: screenWidth, height: height, fit: BoxFit.contain),
      width: screenWidth,
      height: height,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FullScreenPage(url), settings: RouteSettings(name: 'FullScreen')),
      );
    },
  );
}

