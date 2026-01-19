import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wingtip/core/talaria_client.dart';

void main() {
  group('TalariaClient', () {
    late Dio mockDio;
    late TalariaClient talariaClient;
    const testDeviceId = 'test-device-123';

    setUp(() {
      mockDio = Dio(BaseOptions(baseUrl: 'https://api.talaria.example.com'));
      talariaClient = TalariaClient(
        dio: mockDio,
        deviceId: testDeviceId,
      );
    });

    group('uploadImage', () {
      test('should create multipart request with correct fields', () async {
        // Create a temporary test file
        final testFile = File('test/fixtures/test_image.jpg');
        await testFile.parent.create(recursive: true);
        await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]); // JPEG header

        // Mock the HTTP adapter to intercept the request
        mockDio.httpClientAdapter = _MockHttpClientAdapter(
          onFetch: (options, requestStream, cancelFuture) async {
            expect(options.method, 'POST');
            expect(options.path, '/v3/jobs/scans');
            expect(options.headers['X-Device-ID'], testDeviceId);

            // Verify FormData contains image and device_id
            final formData = options.data as FormData;
            final fields = formData.fields;
            final files = formData.files;

            expect(
              fields.any((field) =>
                  field.key == 'device_id' && field.value == testDeviceId),
              true,
            );
            expect(files.any((file) => file.key == 'image'), true);

            return ResponseBody.fromString(
              '{"jobId": "job-123", "streamUrl": "https://stream.example.com/job-123"}',
              202,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        final response = await talariaClient.uploadImage(testFile.path);

        expect(response.jobId, 'job-123');
        expect(response.streamUrl, 'https://stream.example.com/job-123');

        // Clean up
        await testFile.delete();
      });

      test('should throw DioException on non-202 response', () async {
        final testFile = File('test/fixtures/test_image2.jpg');
        await testFile.parent.create(recursive: true);
        await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);

        mockDio.httpClientAdapter = _MockHttpClientAdapter(
          onFetch: (options, requestStream, cancelFuture) async {
            return ResponseBody.fromString(
              '{"error": "Invalid request"}',
              400,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        expect(
          () => talariaClient.uploadImage(testFile.path),
          throwsA(isA<DioException>()),
        );

        await testFile.delete();
      });
    });

    group('cleanupJob', () {
      test('should send DELETE request to cleanup endpoint', () async {
        const testJobId = 'job-123';

        mockDio.httpClientAdapter = _MockHttpClientAdapter(
          onFetch: (options, requestStream, cancelFuture) async {
            expect(options.method, 'DELETE');
            expect(options.path, '/v3/jobs/scans/$testJobId/cleanup');
            expect(options.headers['X-Device-ID'], testDeviceId);

            return ResponseBody.fromString(
              '',
              204,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        await talariaClient.cleanupJob(testJobId);
      });

      test('should throw DioException on cleanup failure', () async {
        const testJobId = 'job-123';

        mockDio.httpClientAdapter = _MockHttpClientAdapter(
          onFetch: (options, requestStream, cancelFuture) async {
            return ResponseBody.fromString(
              '{"error": "Job not found"}',
              404,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          },
        );

        expect(
          () => talariaClient.cleanupJob(testJobId),
          throwsA(isA<DioException>()),
        );
      });
    });
  });

  group('ScanJobResponse', () {
    test('should parse JSON correctly', () {
      final json = {
        'jobId': 'job-123',
        'streamUrl': 'https://stream.example.com/job-123',
      };

      final response = ScanJobResponse.fromJson(json);

      expect(response.jobId, 'job-123');
      expect(response.streamUrl, 'https://stream.example.com/job-123');
    });
  });
}

class _MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) onFetch;

  _MockHttpClientAdapter({required this.onFetch});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<dynamic>? cancelFuture,
  ) {
    return onFetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
