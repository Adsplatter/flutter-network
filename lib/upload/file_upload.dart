import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:adsplatter/framework/network/upload/upload_event.dart';

class AdsplatterFileUpload {
  /// The URL to upload the file to
  final String url;

  /// The file to upload
  final File file;

  /// The total bytes in the file
  int totalBytes = 0;

  /// Chunk size
  int chunkSize = 1024 * 1024;
  int totalChunks = 0;
  int currentChunk = 0;

  /// Retries
  int retries = 3;
  int retryCount = 0;

  /// Cookie
  String? cookie;

  /// Upload metadata
  HttpResponse? response;
  List<http.StreamedResponse> responseStack = [];

  /// Upload flags
  bool isUploading = false;
  bool uploadFailed = false;
  bool uploadSuccessful = false;
  bool uploadComplete = false;
  bool uploadHasError = false;

  /// Error message
  String? errorMessage;

  /// Stream controller
  final controller = StreamController<UploadEvent>();

  /// Constructor
  AdsplatterFileUpload({required this.url, required this.file, this.cookie}) {
    totalBytes = file.lengthSync();
    totalChunks = (totalBytes / chunkSize).ceil();
  }

  /// Upload the file in chunks with retry logic
  Future<void> uploadMultipart() async {
    int byteCount = 0;
    List<int> fileBytes = await file.readAsBytes(); // Read the file bytes

    while (byteCount < totalBytes) {
      isUploading = true;

      int chunkStart = byteCount;
      int chunkEnd = (byteCount + chunkSize < totalBytes) ? byteCount + chunkSize : totalBytes;
      List<int> chunk = fileBytes.sublist(chunkStart, chunkEnd);
      byteCount += chunk.length;

      try {
        final response = await _uploadChunk(chunk, chunkStart, chunkEnd);

        // Check if the request was unsuccessful
        if (response.statusCode != 200) {
          if (retryCount < retries) {
            byteCount -= chunk.length;
            retryCount++;
            continue;
          }

          // Upload failed
          uploadFailed = true;
          uploadComplete = true;
          uploadHasError = true;
          uploadSuccessful = false;
          isUploading = false;
          errorMessage = response.reasonPhrase ?? 'Unknown error';
          return;
        }

        // Successful upload
        currentChunk++;
        retryCount = 0;

      } catch (e) {

        // Retry the chunk upload if error occurred
        if (retryCount < retries) {
          byteCount -= chunk.length;
          retryCount++;
          continue;
        }

        uploadFailed = true;
        uploadComplete = true;
        uploadHasError = true;
        uploadSuccessful = false;
        isUploading = false;
        errorMessage = e.toString();
        return;
      }
    }

    // Upload finished successfully
    uploadFailed = false;
    uploadComplete = true;
    uploadHasError = false;
    uploadSuccessful = true;
    isUploading = false;
  }

  /// Upload the file in chunks with stream output
  Stream<UploadEvent> uploadMultipartStream() async* {
    int byteCount = 0;
    List<int> fileBytes = await file.readAsBytes(); // Read the file bytes

    while (byteCount < totalBytes) {
      isUploading = true;

      int chunkStart = byteCount;
      int chunkEnd = (byteCount + chunkSize < totalBytes) ? byteCount + chunkSize : totalBytes;
      List<int> chunk = fileBytes.sublist(chunkStart, chunkEnd);
      byteCount += chunk.length;

      try {
        final response = await _uploadChunk(chunk, chunkStart, chunkEnd);

        if (response.statusCode != 200) {
          if (retryCount < retries) {
            byteCount -= chunk.length;
            retryCount++;
            continue;
          }

          uploadFailed = true;
          uploadComplete = true;
          uploadHasError = true;
          uploadSuccessful = false;
          isUploading = false;
          errorMessage = response.reasonPhrase ?? 'Unknown error';

          yield _createUploadEvent(byteCount);
          return;
        }

        currentChunk++;
        retryCount = 0;

      } catch (e) {
        if (retryCount < retries) {
          byteCount -= chunk.length;
          retryCount++;
          continue;
        }

        uploadFailed = true;
        uploadComplete = true;
        uploadHasError = true;
        uploadSuccessful = false;
        isUploading = false;
        errorMessage = e.toString();
        yield _createUploadEvent(byteCount);
        return;
      }

      yield _createUploadEvent(byteCount);
    }

    // Upload finished successfully
    uploadFailed = false;
    uploadComplete = true;
    uploadHasError = false;
    uploadSuccessful = true;
    isUploading = false;
    yield _createUploadEvent(byteCount);
  }

  /// Close the stream controller when upload is complete
  void close() {
    controller.close();
  }

  /// Helper method to upload a chunk
  Future<http.StreamedResponse> _uploadChunk(List<int> chunk, int chunkStart, int chunkEnd) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    var filePart = http.MultipartFile.fromBytes('file', chunk, filename: file.path.split('/').last);
    request.files.add(filePart);

    if (cookie != null) {
      request.headers['Cookie'] = cookie!;
    }

    request.headers['Content-Type'] = 'application/octet-stream';
    request.headers['Content-Range'] = 'bytes $chunkStart-$chunkEnd/$totalBytes';

    return await request.send();
  }

  /// Helper to create an UploadEvent
  UploadEvent _createUploadEvent(int byteCount) {
    return UploadEvent(
      uploadFailed: uploadFailed,
      uploadSuccessful: uploadSuccessful,
      uploadComplete: uploadComplete,
      uploadHasError: uploadHasError,
      isUploading: isUploading,
      errorMessage: errorMessage,
      currentChunk: currentChunk,
      totalChunks: totalChunks,
      currentBytes: byteCount,
      totalBytes: totalBytes,
    );
  }
}

