class UsbDeviceInfo {
  final String driveLetter;
  final String rootPath;
  final String? physicalSerialNumber;
  final String? pnpDeviceId;
  final String? vendorId;
  final String? productId;
  final String? volumeLabel;
  final bool isRemovable;
  final int totalBytes;
  final int freeBytes;

  const UsbDeviceInfo({
    required this.driveLetter,
    required this.rootPath,
    required this.physicalSerialNumber,
    required this.pnpDeviceId,
    required this.vendorId,
    required this.productId,
    required this.volumeLabel,
    required this.isRemovable,
    required this.totalBytes,
    required this.freeBytes,
  });

  bool get hasReliableSerial =>
      physicalSerialNumber != null && physicalSerialNumber!.trim().isNotEmpty;

  bool get isSupported => isRemovable && hasReliableSerial;

  factory UsbDeviceInfo.fromMap(Map<Object?, Object?> map) {
    String? optionalString(String key) {
      final value = map[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return UsbDeviceInfo(
      driveLetter: map['driveLetter']?.toString() ?? '',
      rootPath: map['rootPath']?.toString() ?? '',
      physicalSerialNumber: optionalString('physicalSerialNumber'),
      pnpDeviceId: optionalString('pnpDeviceId'),
      vendorId: optionalString('vendorId'),
      productId: optionalString('productId'),
      volumeLabel: optionalString('volumeLabel'),
      isRemovable: map['isRemovable'] == true,
      totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
      freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
