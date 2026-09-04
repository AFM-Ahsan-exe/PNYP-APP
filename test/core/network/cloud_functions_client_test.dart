import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:pynp_app/core/network/cloud_functions_client.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri());
  });

  group('CloudFunctionsClient', () {
    late MockHttpClient mockClient;
    late CloudFunctionsClient client;

    setUp(() {
      mockClient = MockHttpClient();
      client = CloudFunctionsClient(
        projectId: 'test-project',
        region: 'us-central1',
        client: mockClient,
      );
    });

    test('returns parsed JSON on successful call', () async {
      final response = http.Response(jsonEncode({'data': 'ok'}), 200);
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => response);

      final result = await client.call('testFunction', {
        'key': 'value',
      }, 'token');
      expect(result['data'], 'ok');
    });

    test('throws StateError with clear message on 404', () async {
      final response = http.Response('Not Found', 404);
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => client.call('missingFunction', {}, 'token'),
        throwsA(
          predicate(
            (e) => e is StateError && e.message.contains('not deployed yet'),
          ),
        ),
      );
    });

    test('throws StateError with server message on non-200', () async {
      final response = http.Response('Server error', 500);
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => client.call('testFunction', {}, 'token'),
        throwsA(
          predicate(
            (e) => e is StateError && e.message.contains('Server error'),
          ),
        ),
      );
    });

    test('throws StateError with function error message', () async {
      final response = http.Response(
        jsonEncode({
          'error': {'message': 'Custom error message'},
        }),
        200,
      );
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => response);

      expect(
        () => client.call('testFunction', {}, 'token'),
        throwsA(
          predicate(
            (e) =>
                e is StateError && e.message.contains('Custom error message'),
          ),
        ),
      );
    });

    test('throws StateError on network exception', () async {
      when(
        () => mockClient.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenThrow(http.ClientException('Network error'));

      expect(
        () => client.call('testFunction', {}, 'token'),
        throwsA(
          predicate(
            (e) => e is StateError && e.message.contains('Network error'),
          ),
        ),
      );
    });
  });
}
