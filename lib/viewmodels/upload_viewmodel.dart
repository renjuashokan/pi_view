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

  Future<bool> uploadFiles(String serverIp, String currentPath, List<File> files) async {
    _isUploading = true;
    _error = null;
    _totalFiles = files.length;
    _uploadedFiles = 0;
    notifyListeners();

    bool allSuccess = true;

    for (var file in files) {
      bool success = await _uploadSingleFile(serverIp, currentPath, file);
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

  Future<bool> _uploadSingleFile(String serverIp, String currentPath, File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$serverIp:8080/api/v1/uploadfile'),
      );

      request.fields['user'] = 'default';
      request.fields['location'] = currentPath;
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to upload file. Status code: ${response.statusCode}');
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