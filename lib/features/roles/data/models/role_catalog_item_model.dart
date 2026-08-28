import '../../domain/entities/role_catalog_item.dart';

class RoleCatalogItemModel extends RoleCatalogItem {
  const RoleCatalogItemModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory RoleCatalogItemModel.fromJson(Map<String, dynamic> json) {
    return RoleCatalogItemModel(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
    );
  }
}
