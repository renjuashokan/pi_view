import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/image_item.dart';

class ImageView extends StatefulWidget {
  final String serverAddress;
  final ImageItem imageItem;
  final List<ImageItem> allImages;

  const ImageView({
    Key? key,
    required this.serverAddress,
    required this.imageItem,
    required this.allImages,
  }) : super(key: key);

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  late PageController pageController;
  late int currentIndex;
  bool isGridView = false;
  int gridCrossAxisCount = 3;
  final TransformationController _transformationController =
      TransformationController();
  bool _dependenciesInitialized = false;

  @override
  void initState() {
    super.initState();
    currentIndex =
        widget.allImages.indexWhere((img) => img.name == widget.imageItem.name);
    pageController = PageController(initialPage: currentIndex);
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_dependenciesInitialized) {
      _preloadImages();
      _dependenciesInitialized = true;
    }
  }

  void _preloadImages() {
    if (!mounted) return;

    // Preload adjacent images
    final startIdx = (currentIndex - 2).clamp(0, widget.allImages.length - 1);
    final endIdx = (currentIndex + 3).clamp(0, widget.allImages.length);

    for (var i = startIdx; i < endIdx; i++) {
      precacheImage(
        CachedNetworkImageProvider(_getImageUrl(widget.allImages[i])),
        context,
      );
    }
  }

  String _getImageUrl(ImageItem item) {
    String encodedPath = Uri.encodeComponent(item.path)
        .replaceAll('%2F', '/')
        .replaceAll('%27', "'")
        .replaceAll('%C3%A2%C2%80%C2%99', '%E2%80%99')
        .replaceAll('%23', '#')
        .replaceAll('%2C', ',');

    return 'http://${widget.serverAddress}:8080/api/v1/file/$encodedPath';
  }

  void _onTransformChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();

    int newCount;
    if (scale <= 0.8) {
      newCount = 4;
    } else if (scale <= 1.2) {
      newCount = 3;
    } else if (scale <= 1.5) {
      newCount = 2;
    } else {
      newCount = 1;
    }

    if (newCount != gridCrossAxisCount) {
      setState(() {
        gridCrossAxisCount = newCount;
      });
    }
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
    // Call preload after page change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadImages();
    });
  }

  void _toggleViewMode() {
    setState(() {
      isGridView = !isGridView;
      if (!isGridView) {
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  void _switchToFullView(int index) {
    setState(() {
      currentIndex = index;
      isGridView = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        pageController.jumpToPage(index);
      }
    });
  }

  Widget _buildImageWithErrorHandler(ImageItem item,
      {BoxFit fit = BoxFit.contain}) {
    return CachedNetworkImage(
      imageUrl: _getImageUrl(item),
      fit: fit,
      memCacheWidth: 1024, // Adjust based on your needs
      memCacheHeight: 1024,
      maxHeightDiskCache: 1500,
      maxWidthDiskCache: 1500,
      errorWidget: (context, url, error) {
        print('Error loading image: ${error.toString()}');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading image',
                style: TextStyle(color: Colors.grey[400]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
      progressIndicatorBuilder: (context, url, downloadProgress) {
        return Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
            color: Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return InteractiveViewer(
      transformationController: _transformationController,
      minScale: 0.5,
      maxScale: 2.0,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: gridCrossAxisCount,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
        ),
        itemCount: widget.allImages.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _switchToFullView(index),
            child: Hero(
              tag: widget.allImages[index].path,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: currentIndex == index
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageWithErrorHandler(
                    widget.allImages[index],
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullScreenView() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: <Widget>[
        PhotoViewGallery.builder(
          scrollPhysics: const BouncingScrollPhysics(),
          builder: (BuildContext context, int index) {
            return PhotoViewGalleryPageOptions.customChild(
              child: _buildImageWithErrorHandler(widget.allImages[index]),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained * 0.8,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(
                tag: widget.allImages[index].path,
              ),
            );
          },
          itemCount: widget.allImages.length,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          pageController: pageController,
          onPageChanged: onPageChanged,
        ),
        Container(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            "${currentIndex + 1} / ${widget.allImages.length}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17.0,
              decoration: null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.allImages[currentIndex].name),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.white24,
            height: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isGridView ? Icons.fullscreen : Icons.grid_view),
            color: Colors.white,
            onPressed: _toggleViewMode,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            color: Colors.white,
            onPressed: () {
              // Implement share functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            color: Colors.white,
            onPressed: () {
              // Implement download functionality
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Colors.black),
        constraints: BoxConstraints.expand(
          height: MediaQuery.of(context).size.height,
        ),
        child: isGridView ? _buildGridView() : _buildFullScreenView(),
      ),
    );
  }
}
