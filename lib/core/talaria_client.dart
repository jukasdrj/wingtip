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
  Future<ScanJobResponse> uploadImage(String imagePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
      'device_id': _deviceId,
    });

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
}
