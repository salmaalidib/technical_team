import 'package:equatable/equatable.dart';

abstract class FilesEvent extends Equatable {
  const FilesEvent();

  @override
  List<Object?> get props => [];
}

class LoadFiles extends FilesEvent {
  const LoadFiles();
}

/// Creates a file definition when [id] is null, otherwise updates it.
class SaveFileRequested extends FilesEvent {
  final int? id;
  final String name;
  final String fileType;
  final String classification;

  const SaveFileRequested({
    this.id,
    required this.name,
    required this.fileType,
    required this.classification,
  });

  @override
  List<Object?> get props => [id, name, fileType, classification];
}
