/// The Upload Event
class UploadEvent {
  final bool uploadFailed;
  final bool uploadSuccessful;
  final bool uploadComplete;
  final bool uploadHasError;
  final bool isUploading;
  final String? errorMessage;

  final int currentChunk;
  final int totalChunks;
  final int currentBytes;
  final int totalBytes;

  UploadEvent({
    required this.uploadFailed,
    required this.uploadSuccessful,
    required this.uploadComplete,
    required this.uploadHasError,
    required this.isUploading,
    this.errorMessage,
    required this.currentChunk,
    required this.totalChunks,
    required this.currentBytes,
    required this.totalBytes,
  });
}
