import 'package:dio/dio.dart';

class ErrorHandler {

  static String handle(dynamic error) {

    print("ERROR: $error");

    // DIO ERRORS
    if (error is DioException) {

      final response = error.response?.data;

      // إذا الريسبونس فيه message
      if (response != null &&
          response is Map &&
          response["message"] != null) {

        return response["message"].toString();
      }

      // إذا ما فيه message
      return "حدث خطأ في الخادم";
    }

    // أي خطأ ثاني
    return "حدث خطأ غير متوقع";
  }
}