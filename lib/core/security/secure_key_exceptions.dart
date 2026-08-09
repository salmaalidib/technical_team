class UsbSecurityException implements Exception {
  final String message;

  const UsbSecurityException(this.message);

  @override
  String toString() => message;
}

class UsbNotFoundException extends UsbSecurityException {
  const UsbNotFoundException()
      : super('يجب توصيل واختيار وحدة تخزين USB صالحة لحفظ المفتاح');
}

class UsbRequiredException extends UsbSecurityException {
  const UsbRequiredException()
      : super('يجب استخدام وحدة تخزين USB حقيقية لحفظ المفتاح');
}

class UnsupportedUsbDeviceException extends UsbSecurityException {
  const UnsupportedUsbDeviceException()
      : super('وحدة USB المحددة غير مدعومة لإنشاء مفتاح مرتبط');
}

class UsbFingerprintUnavailableException extends UsbSecurityException {
  const UsbFingerprintUnavailableException()
      : super(
            'لا تحتوي وحدة USB على رقم تسلسلي موثوق، لذلك لا يمكن ربط المفتاح بها');
}

class UsbDisconnectedException extends UsbSecurityException {
  const UsbDisconnectedException()
      : super('تم فصل وحدة USB أثناء إنشاء المفتاح');
}

class KeyMustRemainOnUsbException extends UsbSecurityException {
  const KeyMustRemainOnUsbException()
      : super('يجب استخدام المفتاح مباشرة من وحدة USB التي أُنشئ عليها');
}

class KeyBoundToAnotherUsbException extends UsbSecurityException {
  const KeyBoundToAnotherUsbException()
      : super('هذا المفتاح مرتبط بوحدة تخزين USB أخرى');
}

class LegacyKeyPackageException extends UsbSecurityException {
  const LegacyKeyPackageException()
      : super(
            'هذا المفتاح قديم وغير مرتبط بوحدة USB. يرجى إعادة إصدار المفتاح.');
}

class InvalidKeyPackageException extends UsbSecurityException {
  const InvalidKeyPackageException()
      : super('ملفات المفتاح غير مكتملة أو غير صالحة');
}

class KeyIntegrityCheckFailedException extends UsbSecurityException {
  const KeyIntegrityCheckFailedException()
      : super('ملفات المفتاح غير متطابقة أو تم تعديلها');
}

class KeyDecryptionFailedException extends UsbSecurityException {
  const KeyDecryptionFailedException()
      : super('رمز PIN غير صحيح أو تم تعديل ملفات المفتاح');
}

class UsbWriteFailedException extends UsbSecurityException {
  const UsbWriteFailedException() : super('تعذّر حفظ المفتاح على وحدة USB');
}
