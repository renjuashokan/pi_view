import 'package:flutter/foundation.dart';
import '../models/media_item.dart';

class MediaPlayerViewModel extends ChangeNotifier {
  final String _serverAddress;
  List<MediaItem> _playlist = [];
  int _currentIndex = 0;
  bool _isLoading = false;
  String? _error;
  MediaItem? _currentMedia;

  MediaPlayerViewModel(this._serverAddress);

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get streamUrl => _currentMedia?.path != null
      ? 'http://$_serverAddress:8080/api/v1/stream/${Uri.encodeFull(_currentMedia!.path)}'
      : null;
  MediaItem? get currentMedia => _currentMedia;
  bool get hasNext => _currentIndex < _playlist.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  void setPlaylist(List<MediaItem> playlist, int initialIndex) {
    _playlist = playlist;
    _currentIndex = initialIndex;
    _updateCurrentMedia();
    _prepareStream();
  }

  void nextVideo() {
    if (hasNext) {
      _currentIndex++;
      _updateCurrentMedia();
      _prepareStream();
    }
  }

  void previousVideo() {
    if (hasPrevious) {
      _currentIndex--;
      _updateCurrentMedia();
      _prepareStream();
    }
  }

  void _updateCurrentMedia() {
    _currentMedia = _playlist.isNotEmpty ? _playlist[_currentIndex] : null;
  }

  void _prepareStream() {
    if (_currentMedia == null) {
      setError('No media selected');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // The streamUrl getter now handles URL construction
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      setError('Error preparing stream: $e');
    }
  }

  void setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }
}
