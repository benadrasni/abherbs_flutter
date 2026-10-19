import 'package:abherbs_flutter/seen/serializer.dart';

const String observationId = "id";
const String observationPlant = "plant";
const String observationLatitude = "latitude";
const String observationLongitude = "longitude";
const String observationPhotoPaths = "photoPaths";
const String observationNote = "note";
const String observationDate = "date";
const String observationTime = "time";
const String observationOrder = "order";
const String observationIndoors = "indoors";
const String observationCountry = "country";
const String observationStatus = "status";
const String observationStatusPrivate = "private";
const String observationConfirmed = "confirmed";
const String observationSource = "source";
const String observationCandidates = "candidates";
const String observationSourceCamera = "camera";
const String observationSourceManual = "manual";

/// Private row only, set after every photo of that find is in
/// `private/{uid}/`. A full [Observation.toJson] save omits it, and Share
/// must not copy it onto a public Sighting.
const String observationPhotoCloud = "photoCloud";

class Observation {
  String key = "";
  String id = "";
  String plant = "";
  DateTime date = DateTime.now();
  double longitude = 0.0;
  double latitude = 0.0;
  String note = "";
  List<dynamic> photoPaths = [];
  String status = observationStatusPrivate;
  int order = 0;
  bool indoors = false;

  /// Missing on older records, which are already confirmed finds.
  bool confirmed = true;
  String source = "";
  List<dynamic> candidates = [];

  /// Lowercase ISO country of the coordinates. Empty until a lookup fills it.
  String country = "";

  Observation(String plantName) {
    this.plant = plantName;
  }

  Observation.fromJson(key, Map data) {
    this.key = key;
    this.id = data[observationId];
    this.plant = data[observationPlant];
    this.date = DateTime.fromMillisecondsSinceEpoch(
        data[observationDate][observationTime]);
    this.longitude = data[observationLongitude].toDouble();
    this.latitude = data[observationLatitude].toDouble();
    this.note = data[observationNote] ?? "";
    this.photoPaths = data[observationPhotoPaths] ?? [];
    this.status = data[observationStatus];
    this.order = data[observationOrder];
    this.indoors = data[observationIndoors] ?? false;
    final confirmedValue = data[observationConfirmed];
    this.confirmed = confirmedValue is bool ? confirmedValue : true;
    final sourceValue = data[observationSource];
    this.source = sourceValue is String ? sourceValue : "";
    final candidateValue = data[observationCandidates];
    this.candidates =
        candidateValue is List ? List<dynamic>.from(candidateValue) : [];
    this.country = guideRowCountry(data[observationCountry]) ?? "";
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
    result[observationIndoors] = this.indoors;
    result[observationConfirmed] = this.confirmed;
    if (this.source.isNotEmpty) result[observationSource] = this.source;
    if (this.candidates.isNotEmpty) {
      result[observationCandidates] = this.candidates;
    }
    final country = guideRowCountry(this.country);
    if (country != null) result[observationCountry] = country;
    return result;
  }
}

/// A two-letter ISO code, lowercased. Anything else is no country.
String? guideRowCountry(dynamic value) {
  if (value is! String) return null;
  final code = value.trim().toLowerCase();
  if (code.length != 2) return null;
  for (final unit in code.codeUnits) {
    if (unit < 0x61 || unit > 0x7a) return null;
  }
  return code;
}

/// Firebase path key for a Latin name. Spaces stay; the forbidden characters
/// do not.
String guideObservationPlantKey(String name) {
  final cleaned = name.trim().replaceAll(RegExp(r'[.#$\[\]/]'), '_');
  if (cleaned.isEmpty) return '_';
  return cleaned;
}
