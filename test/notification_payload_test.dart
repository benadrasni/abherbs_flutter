import 'package:abherbs_flutter/data/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notification browse action still matches the FCM payload', () {
    expect(notificationAttributeActionBrowse, 'browse');
    expect(notificationAttributeUri, 'uri');
    expect(notificationAttributeActionPlant, 'plant');
    expect(notificationAttributeActionList, 'list');
  });
}
