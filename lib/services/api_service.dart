import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class ApiService {
  static const String baseUrl =
      'https://asia-south1-veritas-472301.cloudfunctions.net';

  final Dio _dio;

  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print(
              'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          print('ERROR MESSAGE: ${e.message}');
          return handler.next(e);
        },
      ),
    );
  }

  /// Upload file to Cloud Functions
  Future<Map<String, dynamic>> uploadFile({
    required File file,
    required String founderEmail,
    required String fileType,
  }) async {
    try {
      String fileName = file.path.split('/').last;
      print('🚀 API: Preparing upload for: $fileName');
      print('🚀 API: Founder email: $founderEmail');
      print('🚀 API: File type: $fileType');
      
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'file_type': fileType,
        'founder_email': founderEmail,
        'original_name': fileName,
      });

      print('🚀 API: Sending POST to /on_file_upload');
      final response = await _dio.post(
        '/on_file_upload',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('✅ API: Upload successful! Status: ${response.statusCode}');
      print('✅ API: Response data: ${response.data}');
      print('✅ API: Response type: ${response.data.runtimeType}');

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      print('❌ API ERROR: ${e.message}');
      print('❌ API ERROR Response: ${e.response?.data}');
      print('❌ API ERROR Status: ${e.response?.statusCode}');
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? e.message ?? 'Upload failed',
      };
    } catch (e) {
      print('❌ API UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Check memo processing status
  Future<Map<String, dynamic>> checkMemoStatus(String fileName) async {
    try {
      final response = await _dio.get(
        '/check_memo',
        queryParameters: {'fileName': fileName},
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? e.message ?? 'Check failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Get AI recommendations
  Future<Map<String, dynamic>> getAIRecommendations(String founderEmail) async {
    try {
      // Create a new Dio instance with longer timeout for recommendations
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60), // Increased for AI processing
          receiveTimeout: const Duration(seconds: 90), // Increased for AI processing
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        '/ai_feedback',
        data: {
          'founder_email': founderEmail,
          'action': 'recommendations',
        },
      );

      // Parse response data if it's a string
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          print('⚠️  Could not parse response as JSON: $e');
        }
      }

      return {
        'success': true,
        'data': responseData,
      };
    } on DioException catch (e) {
      String errorMessage = 'Request failed';
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.response != null) {
        errorMessage = e.response?.data?['error']?.toString() ?? 
                       e.response?.data?.toString() ?? 
                       'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error';
      }
      
      print('❌ API ERROR (Recommendations): $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ UNEXPECTED ERROR (Recommendations): $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Ask AI a question
  Future<Map<String, dynamic>> askAIQuestion({
    required String founderEmail,
    required String question,
  }) async {
    try {
      // Create a new Dio instance with longer timeout for questions
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 60), // Increased for AI processing
          receiveTimeout: const Duration(seconds: 90), // Increased for AI processing
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      final response = await dio.post(
        '/ai_feedback',
        data: {
          'founder_email': founderEmail,
          'action': 'question',
          'question': question,
        },
      );

      // Parse response data
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          print('⚠️  Could not parse response as JSON: $e');
        }
      }

      return {
        'success': true,
        'data': responseData,
      };
    } on DioException catch (e) {
      String errorMessage = 'Request failed';
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Request timed out. Please try again.';
      } else if (e.response != null) {
        errorMessage = e.response?.data?['error']?.toString() ?? 
                       e.response?.data?.toString() ?? 
                       'Server error: ${e.response?.statusCode}';
      } else {
        errorMessage = e.message ?? 'Network error';
      }
      
      print('❌ API ERROR (Question): $errorMessage');
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ UNEXPECTED ERROR (Question): $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Schedule AI interview
  Future<Map<String, dynamic>> scheduleInterview({
    required String founderEmail,
    required String investorEmail,
    required String startupName,
    String? calendarId,
  }) async {
    try {
      print('📅 API: Scheduling interview POST to /schedule_ai_interview');
      print('📅 API: Data: founder=$founderEmail, investor=$investorEmail, startup=$startupName');
      
      // Generate a company_id from startup name (backend requires it)
      final companyId = startupName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      print('📅 API: Generated company_id: $companyId');
      
      final response = await _dio.post(
        '/schedule_ai_interview',
        data: {
          'founder_email': founderEmail,
          'investor_email': investorEmail,
          'startup_name': startupName,
          'company_id': companyId,
          if (calendarId != null) 'calendar_id': calendarId,
        },
      );

      print('✅ API: Schedule interview success! Status: ${response.statusCode}');
      print('✅ API: Response data: ${response.data}');

      // Parse response data if it's a string
      dynamic responseData = response.data;
      if (responseData is String) {
        responseData = jsonDecode(responseData);
      }

      return {
        'success': true,
        'data': responseData,
      };
    } on DioException catch (e) {
      print('❌ API SCHEDULE ERROR: ${e.message}');
      print('❌ API Status: ${e.response?.statusCode}');
      print('❌ API Response data: ${e.response?.data}');
      print('❌ API Error type: ${e.type}');
      
      // Try to extract a meaningful error message
      String errorMessage = 'Scheduling failed';
      if (e.response?.data != null) {
        if (e.response!.data is Map) {
          errorMessage = e.response!.data['error']?.toString() ?? 
                        e.response!.data['message']?.toString() ?? 
                        e.response!.data.toString();
        } else {
          errorMessage = e.response!.data.toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      return {
        'success': false,
        'error': errorMessage,
      };
    } catch (e) {
      print('❌ API UNEXPECTED ERROR: $e');
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Run diligence validation
  Future<Map<String, dynamic>> runDiligence({
    required String companyId,
    required String investorEmail,
  }) async {
    try {
      final response = await _dio.post(
        '/run_diligence',
        data: {
          'company_id': companyId,
          'investor_email': investorEmail,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? e.message ?? 'Diligence failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Query diligence with RAG
  Future<Map<String, dynamic>> queryDiligence({
    required String companyId,
    required String question,
  }) async {
    try {
      final response = await _dio.post(
        '/query_diligence',
        data: {
          'company_id': companyId,
          'question': question,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? e.message ?? 'Query failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }

  /// Trigger manual diligence
  Future<Map<String, dynamic>> triggerDiligence({
    required String memo1Id,
    String? gaPropertyId,
    String? linkedinUrl,
  }) async {
    try {
      final response = await _dio.post(
        '/trigger_diligence',
        data: {
          'memo_1_id': memo1Id,
          if (gaPropertyId != null) 'ga_property_id': gaPropertyId,
          if (linkedinUrl != null) 'linkedin_url': linkedinUrl,
        },
      );

      return {
        'success': true,
        'data': response.data,
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'error':
            e.response?.data?['error'] ?? e.message ?? 'Trigger failed',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Unexpected error: $e',
      };
    }
  }
}

