import 'package:abherbs_flutter/entity/serializer.dart';

const String observationId = "id";
const String observationPlant = "plant";
const String observationLatitude = "latitude";
const String observationLongitude = "longitude";
const String observationPhotoPaths = "photoPaths";
const String observationNote = "note";
const String observationDate = "date";
const String observationTime = "time";
const String observationOrder = "order";
const String observationStatus = "status";
const String observationStatusPrivate = "private";
const String observationStatusPublic = "public";

class Observation{
  String key;
  String id;
  String plant;
  DateTime date;
  double longitude;
  double latitude;
  String note;
  List<dynamic> photoPaths;
  String status;
  int order;

  Observation(String plantName) {
    this.plant = plantName;
    this.date = DateTime.now();
    this.photoPaths = [];
    this.status = observationStatusPrivate;
  }

  Observation.fromJson(key, Map data) {
    this.key = key;
    this.id = data[observationId];
    this.plant = data[observationPlant];
    this.date = DateTime.fromMillisecondsSinceEpoch(data[observationDate][observationTime]);
    this.longitude = data[observationLongitude];
    this.latitude = data[observationLatitude];
    this.note = data[observationNote];
    this.photoPaths = data[observationPhotoPaths];
    this.status = data[observationStatus];
    this.order = data[observationOrder];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {};
    result[observationId] = this.id;
    result[observationPlant] = this.plant;
    result[observationDate] = dateTimeToJson(this.date);
    result[observationLatitude] = this.latitude;
    result[observationLongitude] = this.longitude;
    result[observationNote] = this.note;
    result[observationPhotoPaths] = this.photoPaths;
    result[observationStatus] = this.status;
    result[observationOrder] = this.order;
    return result;
  }
}