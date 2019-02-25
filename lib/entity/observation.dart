const String observationId = "id";
const String observationPlantName = "plant";
const String observationLatitude = "latitude";
const String observationLongitude = "longitude";
const String observationPhotoUrls = "photoPaths";
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
  String plantName;
  DateTime dateTime;
  double longitude;
  double latitude;
  String note;
  List<dynamic> photoUrls;
  String status;
  int order;

  Observation(String plantName) {
    this.plantName = plantName;
    this.dateTime = DateTime.now();
    this.photoUrls = [];
    this.status = observationStatusPrivate;
  }

  Observation.fromJson(key, Map data) {
    this.key = key;
    this.id = data[observationId];
    this.plantName = data[observationPlantName];
    this.dateTime = DateTime.fromMillisecondsSinceEpoch(data[observationDate][observationTime]);
    this.longitude = data[observationLongitude];
    this.latitude = data[observationLatitude];
    this.note = data[observationNote];
    this.photoUrls = data[observationPhotoUrls];
    this.status = data[observationStatus];
    this.order = data[observationOrder];
  }
}