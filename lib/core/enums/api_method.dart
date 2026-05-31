enum ApiMethod { get, post, put, delete, patch }

extension ApiMethodValue on ApiMethod {
  String get value {
    switch (this) {
      case ApiMethod.get:
        return "GET";
      case ApiMethod.post:
        return "POST";
      case ApiMethod.put:
        return "PUT";
      case ApiMethod.delete:
        return "DELETE";
      case ApiMethod.patch:
        return "PATCH";
    }
  }
}
