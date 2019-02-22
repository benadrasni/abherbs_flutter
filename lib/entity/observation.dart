class Observation{
  final String key;
  String plantName;
  DateTime dateTime;
  double longitude;
  double latitude;
  String note;
  List<dynamic> photoUrls;
  String status;
  int order;

  Observation.fromJson(this.key, Map data) {
    plantName = data['plant'];
    dateTime = DateTime.fromMillisecondsSinceEpoch(data['date']['time']);
    longitude = data['longitude'];
    latitude = data['latitude'];
    note = data['note'];
    photoUrls = data['photoUrls'];
    status = data['status'];
    order = data['order'];
  }
}