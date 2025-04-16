import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/io_client.dart';
import 'package:http/http.dart' as http;

class HTTPNetworkService extends http.BaseClient {

  /// Global HTTP client
  static http.Client client = Http11Client();

  /// Send a POST request with robust error handling and configuration
  ///
  /// [url] The target URL for the POST request
  /// [postData] The body of the request
  /// [headers] Optional additional headers
  /// [timeout] Request timeout duration (default 30 seconds)
  static Future<http.Response> sendPostRequest(
      String url,
      dynamic postData,
      {
        Map<dynamic, dynamic>? headers,
        Duration timeout = const Duration(seconds: 10),
      }) async {

    // Prepare headers with default content type
    final defaultHeaders = {'Content-Type': 'application/x-www-form-urlencoded'};

    final requestHeaders = {
      ...defaultHeaders,
      ...?headers
    };

    try {
      // Send the POST request with timeout
      final response = await client.post(
        Uri.parse(url),
        body: postData,
        headers: Map<String, String>.from(requestHeaders),
      ).timeout(
          timeout,
          onTimeout: () => throw TimeoutException('Request to $url timed out')
      );

      // Handle different response status codes
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        throw HttpException('Request failed with status ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      // Specific handling for timeout errors
      throw NetworkException('network Timeout: ${e.message}');
    } on http.ClientException catch (e) {
      // Handle network-related client exceptions
      throw NetworkException('network Error: ${e.message}');
    } catch (e) {
      // Catch-all for any other unexpected errors
      throw NetworkException('Unexpected error: $e');
    }
  }

  /// Send a GET request
  ///
  /// [url] The target URL for the GET request
  /// [headers] Optional additional headers
  static Future<http.Response> sendGetRequest(String url, {Map? headers, Duration timeout = const Duration(seconds: 10)}) async {

    Map<String, String> contentTypeHeader = {'Content-Type': 'application/x-www-form-urlencoded'};

    headers ??= {};

    // Merge contentTypeHeader with headers:
    headers = {...contentTypeHeader, ...headers};

    try {
      // Send POST request after the delay
      final response = await http.get(
        Uri.parse(url),
        headers: Map<String, String>.from(headers),
      );
      return response;
    } catch (error) {
      // Handle errors
      rethrow;
    }
  }

  @override
  Future<void> close() async => client.close();

  @override
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => client.delete(url, headers: headers);

  @override
  Future<http.Response> get(Uri url, {Map<String, String>? headers}) => client.get(url, headers: headers);

  @override
  Future<http.Response> head(Uri url, {Map<String, String>? headers}) => client.head(url, headers: headers);

  @override
  Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => client.patch(url, headers: headers);

  @override
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => client.post(url, headers: headers);

  @override
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) => client.put(url, headers: headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) => client.send(request);

  @override
  Future<String> read(Uri url, {Map<String, String>? headers}) => client.read(url, headers: headers);

  @override
  Future<Uint8List> readBytes(Uri url, {Map<String, String>? headers}) => client.readBytes(url, headers: headers);
}

/// Custom exceptions defined outside the class
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Custom exception
class HttpException implements Exception {
  final String message;
  HttpException(this.message);

  @override
  String toString() => 'HttpException: $message';
}

/// Http11Client
class Http11Client extends http.BaseClient {
  final HttpClient _inner;

  Http11Client() : _inner = HttpClient() {
    _inner.connectionTimeout = const Duration(seconds: 10);
    _inner.idleTimeout = const Duration(seconds: 10);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // Use IOClient to delegate the actual sending
    return IOClient(_inner).send(request);
  }

  @override
  Future<void> close() async {
    // Close the underlying HttpClient forcefully
    _inner.close(force: true);
    // Call BaseClient's close method
    super.close();
    // Close the IOClient
    return IOClient(_inner).close();
  }

}
