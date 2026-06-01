import '../../domain/entities/location_option.dart';

class LocationOptionModel extends LocationOption {
  const LocationOptionModel({required super.id, required super.name});

  factory LocationOptionModel.fromJson(Map<String, dynamic> json) {
    return LocationOptionModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
    );
  }
}
