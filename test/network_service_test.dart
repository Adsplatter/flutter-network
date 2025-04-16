import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';

import 'package:flutter_network/network_service.dart';

void main() {
  group('HTTPNetworkService', () {
    test('sendPostRequest returns successful response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        return http.Response('{"success": true}', 200);
      });

      HTTPNetworkService.client = mockClient; // <- overriding the static client

      final response = await HTTPNetworkService.sendPostRequest(
        'http://fake.url/post',
        {'key': 'value'},
      );

      expect(response.statusCode, equals(200));
      expect(response.body, contains('success'));
    });

    test('sendPostRequest throws HttpException on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('error', 500);
      });

      HTTPNetworkService.client = mockClient;

      expect(
        () => HTTPNetworkService.sendPostRequest('http://fake.url/post', {}),
        throwsA(isA<NetworkException>()),
      );
    });

    test('sendPostRequest throws TimeoutException', () async {
      final mockClient = MockClient((request) async {
        await Future.delayed(Duration(seconds: 2));
        return http.Response('delayed', 200);
      });

      HTTPNetworkService.client = mockClient;

      expect(
        () => HTTPNetworkService.sendPostRequest(
          'http://fake.url/post',
          {},
          timeout: Duration(milliseconds: 500),
        ),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
