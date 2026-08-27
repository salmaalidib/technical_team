import '../../domain/entities/type_location_option.dart';

class TypeLocationOptionModel extends TypeLocationOption {
  const TypeLocationOptionModel({
    required super.id,
    required super.name,
  });

  factory TypeLocationOptionModel.fromJson(Map<String, dynamic> json) {
    return TypeLocationOptionModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
    );
  }
}
