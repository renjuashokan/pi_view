import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../viewmodels/file_browser_viewmodel.dart';
import '../viewmodels/upload_viewmodel.dart';
import '../widgets/base_page.dart';
import '../widgets/pagination_control.dart';
import '../models/file_item.dart';
import '../models/media_item.dart';
import '../models/image_item.dart';

class FileBrowserView extends StatefulWidget {
  final String serverIp;
  final String serverPort;

  const FileBrowserView(
      {Key? key, required this.serverIp, required this.serverPort})
      : super(key: key);

  @override
  State<FileBrowserView> createState() => _FileBrowserViewState();
}

class _FileBrowserViewState extends State<FileBrowserView> {
  bool _isGridView = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';
  FileBrowserViewModel? _viewModel;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _viewModel?.loadNextPageIfNeeded();
    }
  }

  Widget _buildThumbnail(
      BuildContext context, FileBrowserViewModel viewModel, FileItem file) {
    if (file.isDirectory) {
      // Return a folder icon for directories
      return const Icon(Icons.folder, size: 48, color: Colors.blue);
    }

    // Get the thumbnail URL from the ViewModel
    final thumbnailUrl = viewModel.getThumbnailUrl(file);

    if (thumbnailUrl != null) {
      return FutureBuilder(
        future: NetworkImage(thumbnailUrl).obtainKey(ImageConfiguration.empty),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Icon(Icons.broken_image,
                  size: 48, color: Colors.grey);
            } else {
              return Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image,
                      size: 48, color: Colors.grey);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              );
            }
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    }

    // Return a default file icon if no thumbnail is available
    return const Icon(Icons.insert_drive_file, size: 48, color: Colors.grey);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final viewModel =
                FileBrowserViewModel(widget.serverIp, widget.serverPort)
                  ..fetchFiles();
            _viewModel = viewModel;
            return viewModel;
          },
        ),
        ChangeNotifierProvider(create: (_) => UploadViewModel()),
      ],
      child: Consumer2<FileBrowserViewModel, UploadViewModel>(
        builder: (context, fileBrowserViewModel, uploadViewModel, child) {
          _viewModel = fileBrowserViewModel;
          final filteredFiles = fileBrowserViewModel.files;
          return BasePage(
            onWillPop: () async {
              if (fileBrowserViewModel.currentPath == '.' ||
                  fileBrowserViewModel.currentPath == '\$') {
                return true;
              } else {
                fileBrowserViewModel.navigateUp();
                return false;
              }
            },
            child: Scaffold(
              appBar: _buildAppBar(context, fileBrowserViewModel),
              body: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!_isSearching) ...[
                        _buildBreadcrumb(fileBrowserViewModel),
                        _buildFileCountAndSort(
                            context, fileBrowserViewModel, filteredFiles),
                      ],
                      Expanded(
                        child:
                            _buildFileList(fileBrowserViewModel, filteredFiles),
                      ),
                      if (uploadViewModel.isUploading)
                        _buildUploadProgress(uploadViewModel),
                      if (uploadViewModel.error != null)
                        _buildErrorMessage(uploadViewModel),
                    ],
                  ),
                ],
              ),
              floatingActionButton: Padding(
                padding: const EdgeInsets.only(
                    bottom: 64.0), // Add padding to avoid overlap
                child: FloatingActionButton(
                  onPressed: () => _showOptions(
                      context, fileBrowserViewModel, uploadViewModel),
                  child: const Icon(Icons.add),
                ),
              ),
              bottomNavigationBar: PaginationControls(
                currentPage: fileBrowserViewModel.currentPage,
                totalPages: fileBrowserViewModel.totalPages,
                isLoading: fileBrowserViewModel.isLoading,
                onPageChanged: (page) => fileBrowserViewModel.goToPage(page),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage(UploadViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(viewModel.error!, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildFileCountAndSort(BuildContext context,
      FileBrowserViewModel viewModel, List<FileItem> files) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${files.length} items in total'),
          _buildSortButton(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb(FileBrowserViewModel viewModel) {
    if (viewModel.viewMode == ViewMode.videosOnly) {
      return const SizedBox.shrink(); // Hide breadcrumb in videos-only mode
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          for (int i = 0; i < viewModel.pathSegments.length; i++)
            InkWell(
              onTap: () => viewModel.navigateToPath(i),
              child: Text(
                '${viewModel.pathSegments[i]}${i < viewModel.pathSegments.length - 1 ? ' / ' : ''}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFileList(FileBrowserViewModel viewModel, List<FileItem> files) {
    if (viewModel.error != null) {
      return Center(child: Text(viewModel.error!));
    }
    if (files.isEmpty && !viewModel.isLoading) {
      return Center(
          child: Text(_searchQuery.isEmpty
              ? 'This folder is empty'
              : 'No search results'));
    }

    return Column(
      children: [
        Expanded(
          child: _isGridView
              ? _buildPaginatedGridView(viewModel, files)
              : _buildPaginatedListView(viewModel, files),
        ),
        if (viewModel.isLoading && files.isNotEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildPaginatedGridView(
      FileBrowserViewModel viewModel, List<FileItem> files) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length + (viewModel.hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == files.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildGridItem(context, viewModel, files[index]);
      },
    );
  }

  Widget _buildPaginatedListView(
      FileBrowserViewModel viewModel, List<FileItem> files) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: files.length + (viewModel.hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == files.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        return _buildFileListItem(context, viewModel, files[index]);
      },
    );
  }

  Widget _buildGridView(FileBrowserViewModel viewModel, List<FileItem> files) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildGridItem(context, viewModel, file);
      },
    );
  }

  Widget _buildUploadProgress(UploadViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: viewModel.uploadedFiles / viewModel.totalFiles,
          ),
          SizedBox(height: 4),
          Text(
              'Uploading ${viewModel.uploadedFiles}/${viewModel.totalFiles} files'),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context, FileBrowserViewModel viewModel, FileItem file) {
    final bool isVideo = viewModel.isVideo(file.fullName);
    final bool isPicture = viewModel.isPicture(file.fullName);

    return InkWell(
      onTap: file.isDirectory
          ? () => viewModel.navigateToDirectory(file.fullName)
          : () => _handleFileOpen(context, viewModel, file, isVideo, isPicture),
      child: Card(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  child: _buildThumbnail(context, viewModel, file),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.fullName,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                  // Text(
                  //   viewModel.formatFileSize(file.size),
                  //   style: TextStyle(fontSize: 10, color: Colors.grey),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileOpen(BuildContext context, FileBrowserViewModel viewModel,
      FileItem file, bool isVideo, bool isPicture) {
    if (isVideo) {
      final mediaItems = viewModel.files
          .where((f) => viewModel.isVideo(f.fullName))
          .map((f) => MediaItem(
                name: f.fullName,
                path: viewModel.currentPath == '.'
                    ? f.fullName
                    : '${viewModel.currentPath}/${f.fullName}',
              ))
          .toList();
      final currentIndex =
          mediaItems.indexWhere((item) => item.name == file.fullName);

      Navigator.of(context).pushNamed(
        '/media_player',
        arguments: {
          'serverAddress': widget.serverIp,
          'serverPort': widget.serverPort,
          'playlist': mediaItems,
          'initialIndex': currentIndex,
        },
      );
    } else if (isPicture) {
      final allImages = viewModel.files
          .where((f) => viewModel.isPicture(f.fullName))
          .map((f) => ImageItem(
                name: f.fullName,
                path: viewModel.currentPath == '.'
                    ? f.fullName
                    : '${viewModel.currentPath}/${f.fullName}',
              ))
          .toList();

      final imageItem = ImageItem(
          name: file.fullName,
          path: viewModel.currentPath == '.'
              ? file.fullName
              : '${viewModel.currentPath}/${file.fullName}');
      Navigator.of(context).pushNamed('/image_viewer', arguments: {
        'serverAddress': widget.serverIp,
        'serverPort': widget.serverPort,
        'imageItem': imageItem,
        'allImages': allImages,
      });
    }
  }

  Widget _buildListView(FileBrowserViewModel viewModel, List<FileItem> files) {
    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _buildFileListItem(context, viewModel, file);
      },
    );
  }

  AppBar _buildAppBar(BuildContext context, FileBrowserViewModel viewModel) {
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
              viewModel.searchFiles('');
            });
          },
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search files...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _searchDebounce?.cancel();
            _searchDebounce = Timer(const Duration(milliseconds: 500), () {
              viewModel.searchFiles(value);
            });
          },
        ),
      );
    }

    return AppBar(
      title:
          Text(viewModel.viewMode == ViewMode.all ? 'File Browser' : 'Videos'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (viewModel.currentPath == '.' || viewModel.currentPath == '\$') {
            Navigator.pop(context);
          } else {
            viewModel.navigateUp();
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(viewModel.viewMode == ViewMode.all
              ? Icons.video_library
              : Icons.folder),
          onPressed: () => viewModel.toggleViewMode(),
          tooltip: viewModel.viewMode == ViewMode.all
              ? 'Show Videos Only'
              : 'Show All Files',
        ),
        IconButton(
          icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
          onPressed: () => setState(() => _isGridView = !_isGridView),
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => setState(() => _isSearching = true),
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  Widget _buildSortButton(
      BuildContext context, FileBrowserViewModel viewModel) {
    return PopupMenuButton<SortCriteria>(
      child: Row(
        children: [
          Text(
            _getSortCriteriaName(viewModel.sortCriteria),
            style: const TextStyle(color: Colors.blue),
          ),
          Icon(
            viewModel.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: Colors.blue,
          ),
        ],
      ),
      onSelected: (SortCriteria criteria) {
        viewModel.setSortCriteria(criteria);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<SortCriteria>>[
        _buildPopupMenuItem(SortCriteria.timeEdited, 'Time Edited', viewModel),
        _buildPopupMenuItem(SortCriteria.size, 'Size', viewModel),
        _buildPopupMenuItem(SortCriteria.filename, 'Filename', viewModel),
        _buildPopupMenuItem(SortCriteria.type, 'Type', viewModel),
      ],
    );
  }

  PopupMenuItem<SortCriteria> _buildPopupMenuItem(
      SortCriteria criteria, String label, FileBrowserViewModel viewModel) {
    return PopupMenuItem<SortCriteria>(
      value: criteria,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (viewModel.sortCriteria == criteria)
            Icon(
              viewModel.isAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: Colors.blue,
            ),
        ],
      ),
    );
  }

  String _getSortCriteriaName(SortCriteria criteria) {
    switch (criteria) {
      case SortCriteria.timeEdited:
        return 'Time Edited';
      case SortCriteria.size:
        return 'Size';
      case SortCriteria.filename:
        return 'Filename';
      case SortCriteria.type:
        return 'Type';
    }
  }

  Widget _buildFileListItem(
      BuildContext context, FileBrowserViewModel viewModel, FileItem file) {
    final bool isVideo = viewModel.isVideo(file.fullName);
    final bool isPicture = viewModel.isPicture(file.fullName);

    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: _buildThumbnail(context, viewModel, file),
      ),
      title: Text(file.fullName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${file.isDirectory ? '${file.size} items' : viewModel.formatFileSize(file.size)} | ${DateFormat('M/d/yy').format(file.modifiedTime.toLocal())}',
        style: TextStyle(color: Colors.grey),
      ),
      onTap: file.isDirectory
          ? () => viewModel.navigateToDirectory(file.fullName)
          : () => _handleFileOpen(context, viewModel, file, isVideo, isPicture),
    );
  }

  void _showOptions(
      BuildContext context,
      FileBrowserViewModel fileBrowserViewModel,
      UploadViewModel uploadViewModel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.file_upload),
                title: Text('Upload Files'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFiles(context, fileBrowserViewModel, uploadViewModel);
                },
              ),
              ListTile(
                leading: Icon(Icons.create_new_folder),
                title: Text('Create New Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _createNewFolder(context, fileBrowserViewModel);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _uploadFiles(
      BuildContext context,
      FileBrowserViewModel fileBrowserViewModel,
      UploadViewModel uploadViewModel) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);

    if (result != null) {
      List<File> files = result.paths.map((path) => File(path!)).toList();
      bool success = await uploadViewModel.uploadFiles(
        fileBrowserViewModel.serverIp,
        fileBrowserViewModel.serverPort,
        fileBrowserViewModel.currentPath,
        files,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('All files uploaded successfully')),
        );
        fileBrowserViewModel.refreshFiles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Some files failed to upload')),
        );
      }
      uploadViewModel.resetUpload();
    }
  }

  void _createNewFolder(
      BuildContext context, FileBrowserViewModel fileBrowserViewModel) {
    String newFolderName = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New Folder'),
          content: TextField(
            autofocus: true,
            decoration: InputDecoration(hintText: 'Enter folder name'),
            onChanged: (value) {
              newFolderName = value;
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
              child: Text('Create'),
              onPressed: () async {
                if (newFolderName.isNotEmpty) {
                  Navigator.of(context).pop();
                  bool success =
                      await fileBrowserViewModel.createFolder(newFolderName);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Folder created successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to create folder')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
