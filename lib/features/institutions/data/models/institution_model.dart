import '../../domain/entities/institution.dart';

class InstitutionModel extends Institution {
  const InstitutionModel({
    required super.id,
    required super.name,
    super.parentId,
    super.locationId,
    super.parentName,
    super.locationName,
  });

  factory InstitutionModel.fromJson(Map<String, dynamic> json) {
    final parent = json['parent'];
    final location = json['location'];

    return InstitutionModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      parentId: json['parent_id'] as int?,
      locationId: json['location_id'] as int?,
      parentName: parent is Map ? parent['name'] as String? : null,
      locationName: location is Map ? location['name'] as String? : null,
    );
  }
}
