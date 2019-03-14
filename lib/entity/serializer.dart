
Map<String, dynamic> dateTimeToJson(DateTime dateTime) {
  Map<String, dynamic> result = {};
  result['year'] = dateTime.year - 1900;
  result['month'] = dateTime.month - 1;
  result['date'] = dateTime.day;
  result['hours'] = dateTime.hour;
  result['minutes'] = dateTime.minute;
  result['seconds'] = dateTime.second;
  result['time'] = dateTime.millisecondsSinceEpoch;
  result['day'] = dateTime.weekday;
  result['timezoneOffset'] = dateTime.timeZoneOffset.inMinutes;
  return result;
}