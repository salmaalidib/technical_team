import 'package:equatable/equatable.dart';

import 'extracted_field.dart';

/// The result of uploading a template PDF to
/// `POST /api/document-templates/extract-fields`: the extracted AcroForm
/// [fields] plus the [path]/[url] the backend assigned to the stored file.
///
/// [path] and [url] must be sent back **verbatim** in the final create call
/// (`POST /api/document-templates`) — the backend re-derives `url` from `path`
/// and rejects the request if they don't match.
class ExtractFieldsResult extends Equatable {
  final List<ExtractedField> fields;
  final String path;
  final String url;

  const ExtractFieldsResult({
    required this.fields,
    required this.path,
    required this.url,
  });

  @override
  List<Object?> get props => [fields, path, url];
}
