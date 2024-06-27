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
  String? key;
  String? id;
  String plant = "";
  DateTime date = DateTime.now();
  double? longitude;
  double? latitude;
  String? note;
  List<dynamic> photoPaths = [];
  String? status;
  String uploadStatus = observationStatusPrivate;
  int? order;

  Observation(String plantName) {
    this.plant = plantName;
  }

  Observation.from(Observation observation) {
    this.key = observation.key;
    this.id = observation.id;
    this.plant = observation.plant;
    this.date = observation.date;
    this.longitude = observation.longitude;
    this.latitude = observation.latitude;
    this.note = observation.note;
    this.photoPaths = List.from(observation.photoPaths);
    this.status = observation.status;
    this.order = observation.order;
  }

  Observation.fromJson(key, Map data) {
    this.key = key;
    this.id = data[observationId];
    this.plant = data[observationPlant];
    this.date = DateTime.fromMillisecondsSinceEpoch(data[observationDate][observationTime]);
    this.longitude = data[observationLongitude].toDouble();
    this.latitude = data[observationLatitude].toDouble();
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