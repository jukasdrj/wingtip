import 'package:dio/dio.dart';

/// Response model for /v3/jobs/scans endpoint
class ScanJobResponse {
  final String jobId;
  final String streamUrl;

  ScanJobResponse({
    required this.jobId,
    required this.streamUrl,
  });

  factory ScanJobResponse.fromJson(Map<String, dynamic> json) {
    return ScanJobResponse(
      jobId: json['jobId'] as String,
      streamUrl: json['streamUrl'] as String,
    );
  }
}

/// Client for interacting with the Talaria API
class TalariaClient {
  final Dio _dio;
  final String _deviceId;

  TalariaClient({
    required Dio dio,
    required String deviceId,
  })  : _dio = dio,
        _deviceId = deviceId;

  /// Upload an image for analysis
  ///
  /// Returns a [ScanJobResponse] containing the jobId and streamUrl for SSE listening.
  /// Throws [DioException] on network errors or non-202 responses.
  ///
  /// [isbnHint] is an optional ISBN detected via barcode scanning that can be passed
  /// as a hint to the backend for faster processing. Backend may ignore this field.
  Future<ScanJobResponse> uploadImage(String imagePath, {String? isbnHint}) async {
    final formFields = <String, dynamic>{
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
      'device_id': _deviceId,
    };

    // Add ISBN hint as multipart form field if available
    if (isbnHint != null) {
      formFields['isbn_hint'] = isbnHint;
    }

    final formData = FormData.fromMap(formFields);

    final response = await _dio.post(
      '/v3/jobs/scans',
      data: formData,
      options: Options(
        headers: {
          'X-Device-ID': _deviceId,
        },
        validateStatus: (status) => status == 202,
      ),
    );

    return ScanJobResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Clean up resources for a completed job
  ///
  /// Sends DELETE request to /v3/jobs/scans/{jobId}/cleanup.
  /// Throws [DioException] on network errors or non-2xx responses.
  Future<void> cleanupJob(String jobId) async {
    await _dio.delete(
      '/v3/jobs/scans/$jobId/cleanup',
      options: Options(
        headers: {
          'X-Device-ID': _deviceId,
        },
      ),
    );
  }
}
