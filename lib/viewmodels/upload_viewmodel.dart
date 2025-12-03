import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

class UploadViewModel extends ChangeNotifier {
  bool _isUploading = false;
  String? _error;
  int _totalFiles = 0;
  int _uploadedFiles = 0;
  double _currentFileProgress = 0.0;

  bool get isUploading => _isUploading;
  String? get error => _error;
  int get totalFiles => _totalFiles;
  int get uploadedFiles => _uploadedFiles;
  double get currentFileProgress => _currentFileProgress;

  Future<bool> uploadFiles(String serverIp, String serverPort,
      String currentPath, List<File> files) async {
    _isUploading = true;
    _error = null;
    _totalFiles = files.length;
    _uploadedFiles = 0;
    notifyListeners();

    bool allSuccess = true;

    for (var file in files) {
      bool success =
          await _uploadSingleFile(serverIp, serverPort, currentPath, file);
      if (!success) {
        allSuccess = false;
      }
      _uploadedFiles++;
      notifyListeners();
    }

    _isUploading = false;
    notifyListeners();
    return allSuccess;
  }

  Future<bool> _uploadSingleFile(
      String serverIp, String serverPort, String currentPath, File file) async {
    try {
      final fileLength = await file.length();
      _currentFileProgress = 0.0;
      notifyListeners();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$serverIp:$serverPort/api/v1/uploadfile'),
      );

      request.fields['user'] = 'default';
      request.fields['location'] = currentPath;

      // Create a stream that tracks upload progress
      var byteStream = file.openRead();
      var streamedFile = http.MultipartFile(
        'file',
        byteStream,
        fileLength,
        filename: file.path.split('/').last,
      );

      request.files.add(streamedFile);

      // Send the request and track progress
      var streamedResponse = await request.send();

      // Listen to response to track upload completion
      if (streamedResponse.statusCode == 200) {
        _currentFileProgress = 1.0;
        notifyListeners();
        return true;
      } else {
        final responseBody = await streamedResponse.stream.bytesToString();
        throw Exception(
            'Failed to upload file. Status code: ${streamedResponse.statusCode}, Response: $responseBody');
      }
    } catch (e) {
      _error = 'Error uploading file ${file.path}: $e';
      notifyListeners();
      return false;
    }
  }

  void resetUpload() {
    _isUploading = false;
    _error = null;
    _totalFiles = 0;
    _uploadedFiles = 0;
    _currentFileProgress = 0.0;
    notifyListeners();
  }
}
