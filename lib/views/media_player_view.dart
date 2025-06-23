import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:auto_orientation/auto_orientation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../viewmodels/media_player_viewmodel.dart';
import '../models/media_item.dart';

class MediaPlayerView extends StatelessWidget {
  final String serverAddress;
  final String serverPort;
  final List<MediaItem> playlist;
  final int initialIndex;

  const MediaPlayerView({
    Key? key,
    required this.serverAddress,
    required this.serverPort,
    required this.playlist,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MediaPlayerViewModel(serverAddress, serverPort)
        ..setPlaylist(playlist, initialIndex),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Media Player'),
        ),
        body: MediaPlayerContent(),
      ),
    );
  }
}

class MediaPlayerContent extends StatefulWidget {
  @override
  _MediaPlayerContentState createState() => _MediaPlayerContentState();
}

class _MediaPlayerContentState extends State<MediaPlayerContent> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  int _skipDuration = 15; // Default skip duration in seconds

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    WakelockPlus.disable();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _initializePlayer(String url) async {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController!,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoPlayerController!.value.aspectRatio,
      allowedScreenSleep: false,
      deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
      fullScreenByDefault: false,
      allowFullScreen: true,
    );

    AutoOrientation.fullAutoMode();

    setState(() {});
  }

  void _skipForward() {
    final newPosition = _videoPlayerController!.value.position +
        Duration(seconds: _skipDuration);
    _videoPlayerController!.seekTo(newPosition);
  }

  void _skipBackward() {
    final newPosition = _videoPlayerController!.value.position -
        Duration(seconds: _skipDuration);
    _videoPlayerController!.seekTo(newPosition);
  }

  void _showSkipDurationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Skip Duration'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Skip duration in seconds'),
            onChanged: (value) {
              setState(() {
                _skipDuration = int.tryParse(value) ?? _skipDuration;
              });
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaPlayerViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SpinKitFadingCircle(
                  color: Colors.blue,
                  size: 50.0,
                ),
                SizedBox(height: 20),
                Text('Preparing your video...'),
              ],
            ),
          );
        }
        if (viewModel.error != null) {
          return Center(child: Text(viewModel.error!));
        }
        if (viewModel.streamUrl != null) {
          if (_videoPlayerController?.dataSource != viewModel.streamUrl) {
            _initializePlayer(viewModel.streamUrl!);
          }
          return Column(
            children: [
              Expanded(
                child: _chewieController != null
                    ? GestureDetector(
                        onDoubleTapDown: (details) {
                          final screenWidth = MediaQuery.of(context).size.width;
                          if (details.localPosition.dx < screenWidth / 2) {
                            _skipBackward();
                          } else {
                            _skipForward();
                          }
                        },
                        child: Chewie(controller: _chewieController!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: _skipBackward,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      onPressed: viewModel.hasPrevious
                          ? () {
                              viewModel.previousVideo();
                              _initializePlayer(viewModel.streamUrl!);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      onPressed: viewModel.hasNext
                          ? () {
                              viewModel.nextVideo();
                              _initializePlayer(viewModel.streamUrl!);
                            }
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: _skipForward,
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showSkipDurationDialog,
                    ),
                  ],
                ),
              ),
              Text('Skip Duration: $_skipDuration seconds'),
            ],
          );
        }
        return const Center(child: Text('Initializing video player...'));
      },
    );
  }
}
