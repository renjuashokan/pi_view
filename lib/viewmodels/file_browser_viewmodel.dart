import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/file_item.dart';

enum SortCriteria { timeEdited, size, filename, type }

enum ViewMode { all, videosOnly }

class FileBrowserViewModel extends ChangeNotifier {
  List<FileItem> _files = [];
  String _currentPath = '.';
  String _serverIp;
  String _serverPort;
  bool _isLoading = false;
  String? _error;
  SortCriteria _sortCriteria = SortCriteria.timeEdited;
  bool _isAscending = false;

  ViewMode _viewMode = ViewMode.all;
  ViewMode get viewMode => _viewMode;

  int _currentPage = 0;
  int _totalFiles = 0;
  static const int itemsPerPage = 25;
  bool _hasMorePages = true;

  FileBrowserViewModel(this._serverIp, this._serverPort);

  List<FileItem> get files => _files;
  String get currentPath => _currentPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  SortCriteria get sortCriteria => _sortCriteria;
  bool get isAscending => _isAscending;
  String get serverIp => _serverIp;
  String get serverPort => _serverPort;
  int get currentPage => _currentPage;
  int get totalPages => (_totalFiles / itemsPerPage).ceil();
  bool get hasMorePages => _hasMorePages;

  bool _isSearchMode = false;
  bool get isSearchMode => _isSearchMode;
  String _searchQuery = '';

  List<String> get pathSegments {
    if (_currentPath == '.') return ['\$'];
    return [
      '\$',
      ..._currentPath.split('/').where((segment) => segment.isNotEmpty)
    ];
  }

  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.all ? ViewMode.videosOnly : ViewMode.all;
    fetchFiles(reset: true);
    notifyListeners();
  }

  String _normalizeServerPath(String path) {
    // Convert internal $ path to . for server requests
    if (path == '\$') return '.';
    // Remove any double slashes and leading/trailing slashes
    return path
        .replaceAll(RegExp(r'\/+'), '/')
        .replaceAll(RegExp(r'^\/+|\/+$'), '');
  }

  String _getApiPath() {
    // For API requests (listing files)
    String apiPath = _currentPath == '\$' ? '.' : _currentPath;
    return _normalizeServerPath(apiPath);
  }

  String _getFilePath(String fileName) {
    // For file/thumbnail URLs
    if (_currentPath == '.' || _currentPath == '\$') {
      return fileName;
    }
    return _normalizeServerPath('${_currentPath}/${fileName}');
  }

  Future<void> searchFiles(String query) async {
    _searchQuery = query;
    _isSearchMode = query.isNotEmpty;
    _currentPage = 0;
    _files = [];

    if (query.isEmpty) {
      _isSearchMode = false;
      await fetchFiles(reset: true);
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = {
        'path': _getApiPath(),
        'query': query,
        'skip': (_currentPage * itemsPerPage).toString(),
        'limit': itemsPerPage.toString(),
      };

      final url = Uri.parse('http://$_serverIp:$_serverPort/api/v1/search')
          .replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final FilePiResponse filePiResponse =
            FilePiResponse.fromJson(json.decode(response.body));

        _totalFiles = filePiResponse.totalFiles;
        _hasMorePages = (_currentPage + 1) * itemsPerPage < _totalFiles;
        _files = filePiResponse.files;
      } else {
        throw Exception(
            'Failed to search files. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error searching files: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchFiles({bool reset = false}) async {
    if (reset) {
      _currentPage = 0;
      _files = [];
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = {
        'path': _getApiPath(),
        'skip': ((_currentPage) * itemsPerPage).toString(),
        'limit': itemsPerPage.toString(),
      };

      if (_sortCriteria != SortCriteria.timeEdited) {
        queryParams['sort_by'] = _getSortByString(_sortCriteria);
        queryParams['order'] = _isAscending ? 'asc' : 'desc';
      }

      final endpoint = _viewMode == ViewMode.all ? 'files' : 'videos';
      if (_viewMode == ViewMode.videosOnly) {
        queryParams['recursive'] = 'true';
      }

      final url =
          Uri.parse('http://${_serverIp}:${_serverPort}/api/v1/$endpoint')
              .replace(queryParameters: queryParams);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final FilePiResponse filePiResponse =
            FilePiResponse.fromJson(json.decode(response.body));

        _totalFiles = filePiResponse.totalFiles;
        _hasMorePages = (_currentPage + 1) * itemsPerPage < _totalFiles;

        if (reset) {
          _files = filePiResponse.files;
        } else {
          _files.addAll(filePiResponse.files);
        }
      } else {
        throw Exception(
            'Failed to fetch files. Status code: ${response.statusCode}');
      }
    } catch (e) {
      _error = 'Error fetching files: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getSortByString(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.timeEdited:
        return 'modified_time';
      case SortCriteria.size:
        return 'size';
      case SortCriteria.filename:
        return 'name';
      case SortCriteria.type:
        return 'file_type';
    }
  }

  Future<void> loadNextPage() async {
    if (!_hasMorePages || _isLoading) return;
    _currentPage++;

    if (_isSearchMode) {
      await searchFiles(_searchQuery);
    } else {
      await fetchFiles();
    }
  }

  Future<void> goToPage(int page) async {
    if (page < 0 || page >= totalPages || _isLoading) return;
    _currentPage = page;
    await fetchFiles(reset: true);
  }

  // void setSortCriteria(SortCriteria criteria) {
  //   if (_sortCriteria == criteria) {
  //     _isAscending = !_isAscending;
  //   } else {
  //     _sortCriteria = criteria;
  //     _isAscending = false;
  //   }
  //   fetchFiles(reset: true);
  // }

  bool isPicture(String filename) {
    return filename.toLowerCase().endsWith('.jpeg') ||
        filename.toLowerCase().endsWith('.png') ||
        filename.toLowerCase().endsWith('.jpg') ||
        filename.toLowerCase().endsWith('.gif') ||
        filename.toLowerCase().endsWith('.bmp') ||
        filename.toLowerCase().endsWith('.webp');
  }

  bool isVideo(String filename) {
    return filename.toLowerCase().endsWith('.mp4') ||
        filename.toLowerCase().endsWith('.avi') ||
        filename.toLowerCase().endsWith('.mkv');
  }

  IconData getFileIcon(FileItem file) {
    if (file.isDirectory) return Icons.folder;
    if (isPicture(file.name)) return Icons.image;
    if (isVideo(file.name)) return Icons.video_file;
    return Icons.insert_drive_file;
  }

  String getThumbnailUrl(FileItem file) {
    String path = _getFilePath(file.fullName);
    String baseUrl = 'http://$_serverIp:${_serverPort}/api/v1';

    if (isVideo(file.name)) {
      return '$baseUrl/thumbnail/${Uri.encodeComponent(path)}';
    } else if (isPicture(file.name)) {
      return '$baseUrl/file/${Uri.encodeComponent(path)}';
    }

    return '';
  }

  void handleFileOpen(FileItem file, BuildContext context) {
    if (file.isDirectory) {
      navigateToDirectory(file.name);
    } else if (isVideo(file.name)) {
      // Handle video navigation
    } else if (isPicture(file.name)) {
      // Handle picture navigation
    }
  }

  void navigateToDirectory(String dirName) {
    if (_currentPath == '.' || _currentPath == '\$') {
      _currentPath = dirName;
    } else {
      _currentPath = '$_currentPath/$dirName';
    }
    _currentPath = _normalizeServerPath(_currentPath);
    fetchFiles(reset: true);
  }

  void navigateToPath(int index) {
    if (index == 0) {
      _currentPath = '.';
    } else {
      _currentPath = pathSegments.sublist(1, index + 1).join('/');
    }
    _currentPath = _normalizeServerPath(_currentPath);
    fetchFiles(reset: true);
  }

  void navigateUp() {
    if (_currentPath == '.' || _currentPath == '\$') {
      return;
    }
    final segments = _currentPath.split('/');
    segments.removeLast();
    _currentPath = segments.isEmpty ? '.' : segments.join('/');
    _currentPath = _normalizeServerPath(_currentPath);
    fetchFiles(reset: true);
  }

  void setSortCriteria(SortCriteria criteria) {
    if (_sortCriteria == criteria) {
      _isAscending = !_isAscending;
    } else {
      _sortCriteria = criteria;
      _isAscending = false;
    }
    _sortFiles();
    notifyListeners();
  }

  void _sortFiles() {
    switch (_sortCriteria) {
      case SortCriteria.timeEdited:
        _files.sort((a, b) => _isAscending
            ? a.modifiedTime.compareTo(b.modifiedTime)
            : b.modifiedTime.compareTo(a.modifiedTime));
        break;
      case SortCriteria.size:
        _files.sort((a, b) =>
            _isAscending ? a.size.compareTo(b.size) : b.size.compareTo(a.size));
        break;
      case SortCriteria.filename:
        _files.sort((a, b) => _isAscending
            ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
            : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
        break;
      case SortCriteria.type:
        _files.sort((a, b) {
          if (a.isDirectory != b.isDirectory) {
            return a.isDirectory ? -1 : 1;
          }
          String extA = a.name.split('.').last.toLowerCase();
          String extB = b.name.split('.').last.toLowerCase();
          return _isAscending ? extA.compareTo(extB) : extB.compareTo(extA);
        });
        break;
    }
  }

  String formatFileSize(int size) {
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double s = size.toDouble();
    while (s >= 1024 && i < suffixes.length - 1) {
      s /= 1024;
      i++;
    }
    return "${s.toStringAsFixed(1)} ${suffixes[i]}";
  }

  Future<bool> createFolder(String folderName) async {
    try {
      final response = await http.post(
        Uri.parse('http://$_serverIp:${_serverPort}/api/v1/createfolder')
            .replace(queryParameters: {
          'path': _getApiPath(),
          'foldername': folderName,
        }),
      );

      if (response.statusCode == 200) {
        await refreshFiles();
        return true;
      } else {
        throw Exception(
            'Failed to create folder. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating folder: $e');
      return false;
    }
  }

  Future<void> refreshFiles() async {
    await fetchFiles();
  }

  void loadNextPageIfNeeded() {
    if (!_isLoading && _hasMorePages) {
      loadNextPage();
    }
  }
}
