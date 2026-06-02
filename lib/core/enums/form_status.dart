/// Status of a form submission (create / update dialogs).
///
/// Kept separate from [RequestStatus] so a screen can load its data and submit
/// a form independently — and so impossible states (a form "loading", a list
/// "submitting") can't be represented.
enum FormStatus { idle, submitting, success, failure }
