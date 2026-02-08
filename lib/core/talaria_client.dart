import 'package:dio/dio.dart';

/// Response model for /v3/jobs/scans endpoint
///
/// API returns: { success, data: { jobId, authToken, sseUrl, statusUrl }, metadata, _links }
class ScanJobResponse {
  final String jobId;
  final String sseUrl;
  final String? authToken;
  final String? statusUrl;

  ScanJobResponse({
    required this.jobId,
    required this.sseUrl,
    this.authToken,
    this.statusUrl,
  });

  factory ScanJobResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return ScanJobResponse(
      jobId: data['jobId'] as String,
      sseUrl: data['sseUrl'] as String,
      authToken: data['authToken'] as String?,
      statusUrl: data['statusUrl'] as String?,
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
  /// Returns a [ScanJobResponse] containing the jobId and sseUrl for SSE listening.
  /// Throws [DioException] on network errors or non-202 responses.
  ///
  /// API expects multipart field name `photos[]` with X-Device-ID header.
  ///
  /// [isbnHint] is an optional ISBN detected via barcode scanning that can be passed
  /// as a hint to the backend for faster processing. Backend may ignore this field.
  Future<ScanJobResponse> uploadImage(String imagePath, {String? isbnHint}) async {
    final formFields = <String, dynamic>{
      'photos[]': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
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
  /// Note: This is a no-op on the server (R2 cleanup is automatic).
  /// Kept for backward compatibility.
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
