import '../../domain/entities/location_option.dart';

class LocationOptionModel extends LocationOption {
  const LocationOptionModel({
    required super.id,
    required super.name,
    super.typeId,
    super.typeName,
  });

  factory LocationOptionModel.fromJson(Map<String, dynamic> json) {
    final type = json['type_location'];
    return LocationOptionModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      typeId: json['typeLocation_id'] as int? ??
          (type is Map<String, dynamic> ? type['id'] as int? : null),
      typeName: type is Map<String, dynamic> ? type['name'] as String? : null,
    );
  }
}
