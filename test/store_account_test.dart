import 'package:abherbs_flutter/purchase/store_account.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uuid v5 matches the DNS example and the server token', () {
    expect(
      uuidV5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'www.example.com'),
      '2ed6657d-e927-568b-95e1-2665a8aea6a2',
    );
    expect(
      storeAccountToken('user-1'),
      '557118bf-c78c-5e3b-8a47-01153acdb216',
    );
  });
}
