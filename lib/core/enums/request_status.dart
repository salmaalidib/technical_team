/// Status of a data-fetching request (lists, detail loads, etc.).
///
/// Shared across feature states so every screen models loading the same way.
enum RequestStatus { initial, loading, success, failure }
