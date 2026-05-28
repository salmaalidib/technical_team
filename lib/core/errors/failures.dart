import 'package:dio/dio.dart';

class ErrorHandler {
  static String handle(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'انتهت مهلة الاتصال بالخادم';
      }

      if (error.type == DioExceptionType.connectionError) {
        return 'تعذر الاتصال بالخادم';
      }

      return 'حدث خطأ في الخادم';
    }

    return 'حدث خطأ غير متوقع';
  }
}