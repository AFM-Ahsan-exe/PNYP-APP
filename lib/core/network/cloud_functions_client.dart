import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudFunctionsClient {
  final String projectId;
  final String region;
  final String baseUrl;
  final http.Client client;

  CloudFunctionsClient({
    required this.projectId,
    this.region = 'us-central1',
    http.Client? client,
  }) : baseUrl = 'https://$region-$projectId.cloudfunctions.net',
       client = client ?? http.Client();

  Future<Map<String, dynamic>> call(
    String functionName,
    Map<String, dynamic> data,
    String? idToken,
  ) async {
    final uri = Uri.parse('$baseUrl/$functionName');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    try {
      debugPrint(
        '[CF] Calling $functionName at $uri with data: $data',
      );

      // Firebase https.onCall requires the request payload
      // to be wrapped inside a top-level "data" field.
      final response = await client
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[CF] $functionName responded with '
        '${response.statusCode}: ${response.body}',
      );

      // A 404 means the HTTPS endpoint itself could not be found.
      // Do not treat 401/403 as "not deployed".
      if (response.statusCode == 404) {
        throw StateError(
          'Cloud function "$functionName" endpoint was not found (HTTP 404).',
        );
      }

      Map<String, dynamic> decoded;

      try {
        final json = jsonDecode(response.body);

        if (json is! Map<String, dynamic>) {
          throw StateError(
            'Unexpected response from "$functionName".',
          );
        }

        decoded = json;
      } on FormatException {
        throw StateError(
          'Cloud function "$functionName" returned an invalid response '
          '(HTTP ${response.statusCode}).',
        );
      }

      // Firebase callable errors are returned inside the "error" field.
      if (decoded['error'] != null) {
        final error = decoded['error'];

        final message = error is Map
            ? error['message']
            : null;

        throw StateError(
          (message as String?) ??
              'Function "$functionName" call failed '
                  '(HTTP ${response.statusCode}).',
        );
      }

      // Handle other HTTP errors without falsely saying the function
      // is not deployed.
      if (response.statusCode != 200) {
        throw StateError(
          'Cloud function "$functionName" request failed '
          '(HTTP ${response.statusCode}): ${response.body}',
        );
      }

      // Firebase callable protocol wraps the actual return value
      // inside the top-level "result" field.
      final result = decoded['result'] ?? decoded['response'];

      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }

      if (result == null) {
        return const {};
      }

      return {
        'value': result,
      };
    } on http.ClientException catch (e) {
      debugPrint(
        '[CF] Network error calling $functionName: ${e.message}',
      );

      throw StateError(
        'Network error calling "$functionName": ${e.message}',
      );
    } on TimeoutException {
      debugPrint(
        '[CF] Timeout calling $functionName',
      );

      throw StateError(
        'Request to "$functionName" timed out.',
      );
    }
  }
}