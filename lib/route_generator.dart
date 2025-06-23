import 'package:flutter/material.dart';
import 'views/login_view.dart';
import 'views/file_browser_view.dart';
import 'views/media_player_view.dart';
import 'views/image_view.dart';
import 'models/media_item.dart';
import 'models/image_item.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Custom page route builder with gesture settings
    PageRoute _buildPageRoute(Widget page) {
      return MaterialPageRoute(
        builder: (_) => page,
        // Enable swipe gestures for all routes
        maintainState: true,
      );
    }

    switch (settings.name) {
      case '/':
        return _buildPageRoute(LoginView());
      case '/file_browser':
        final args = settings.arguments as Map<String, dynamic>?;
        final serverIp = args?['serverIp'] as String? ?? 'localhost';
        final serverPort = args?['serverPort'] as String? ?? '8080';
        return _buildPageRoute(FileBrowserView(
          serverIp: serverIp,
          serverPort: serverPort,
        ));
      case '/media_player':
        final args = settings.arguments as Map<String, dynamic>;
        final serverAddress = args['serverAddress'] as String;
        final serverPort = args['serverPort'] as String? ?? '8080';
        final playlist = args['playlist'] as List<MediaItem>;
        final initialIndex = args['initialIndex'] as int;
        return _buildPageRoute(
          MediaPlayerView(
            serverAddress: serverAddress,
            serverPort: serverPort,
            playlist: playlist,
            initialIndex: initialIndex,
          ),
        );
      case '/image_viewer':
        final args = settings.arguments as Map<String, dynamic>;
        final serverAddress = args['serverAddress'] as String;
        final serverPort = args['serverPort'] as String? ?? '8080';
        final imageItem = args['imageItem'] as ImageItem;
        final allimages = args['allImages'] as List<ImageItem>;
        return _buildPageRoute(
          ImageView(
            serverAddress: serverAddress,
            serverPort: serverPort,
            imageItem: imageItem,
            allImages: allimages,
          ),
        );
      default:
        return _buildPageRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
