class FilePiResponse {
  final int totalFiles;
  final List<FileItem> files;
  final int skip;
  final int limit;

  FilePiResponse({
    required this.totalFiles,
    required this.files,
    required this.skip,
    required this.limit,
  });

  factory FilePiResponse.fromJson(Map<String, dynamic> json) {
    return FilePiResponse(
      totalFiles: json['total_files'] as int,
      files: (json['files'] as List)
          .map((fileJson) => FileItem.fromJson(fileJson))
          .toList(),
      skip: json['skip'] as int,
      limit: json['limit'] as int,
    );
  }
}

class FileItem {
  final String name;
  final int size;
  final bool isDirectory;
  final DateTime createdTime;
  final DateTime modifiedTime;
  final String owner;
  final String? fileType;
  final String fullName;

  FileItem({
    required this.name,
    required this.size,
    required this.isDirectory,
    required this.createdTime,
    required this.modifiedTime,
    required this.owner,
    required this.fullName,
    this.fileType,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      name: json['name'] as String,
      size: json['size'] as int,
      isDirectory: json['is_directory'] as bool,
      createdTime: DateTime.fromMillisecondsSinceEpoch(
          json['created_time'] as int,
          isUtc: true),
      modifiedTime: DateTime.fromMillisecondsSinceEpoch(
          json['modified_time'] as int,
          isUtc: true),
      owner: json['owner'] as String,
      fileType: json['file_type'] as String?,
      fullName: json['full_name'] as String,
    );
  }
}
