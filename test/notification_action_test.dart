import 'package:abherbs_flutter/data/notification_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a push with no action is an empty action', () {
    expect(notificationActionValue(null), isEmpty);
    expect(notificationActionValue({'title': 'Hello'}['action']), isEmpty);
    expect(notificationActionValue('plant'), 'plant');
    expect(notificationActionValue(12), '12');
  });
}
