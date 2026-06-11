import 'package:equatable/equatable.dart';

class FilePickerEntity extends Equatable {
  final int id;
  final String idWidget;
  final String label;
  final bool isRequired;
  final int maxSizeMb;
  final List<String> allowedExtensions;
  final bool allowMultiple;

  const FilePickerEntity({
    required this.id,
    required this.idWidget,
    required this.label,
    required this.isRequired,
    required this.maxSizeMb,
    required this.allowedExtensions,
    required this.allowMultiple,
  });

  @override
  List<Object?> get props => [
        id,
        idWidget,
        label,
        isRequired,
        maxSizeMb,
        allowedExtensions,
        allowMultiple,
      ];
}
