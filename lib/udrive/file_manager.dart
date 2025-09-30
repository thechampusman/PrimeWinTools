import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class UDriveFileManager {
  String storagePath = '';
  List<String> filePaths = []; // For storing file paths without duplication

  void setStoragePath(String path) {
    storagePath = path;
  }

  Future<List<Map<String, dynamic>>> getFiles(String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final directory = Directory(fullPath);

      if (!directory.existsSync()) {
        return [];
      }

      final List<Map<String, dynamic>> fileList = [];

      await for (final entity in directory.list()) {
        final stat = await entity.stat();
        final fileName = path.basename(entity.path);

        // Skip hidden files
        if (fileName.startsWith('.')) continue;

        int fileSize = 0;
        int itemCount = 0;
        if (entity is File) {
          fileSize = stat.size;
        } else if (entity is Directory) {
          // Count items in directory instead of calculating size
          try {
            print('🔍 Counting items in directory: ${entity.path}');
            itemCount = await entity.list().length;
            print('📊 Found $itemCount items in directory: ${fileName}');
          } catch (e) {
            print('❌ Error counting items in directory ${fileName}: $e');
            itemCount = 0; // If we can't access the directory
          }
        }

        final fileInfo = {
          'name': fileName,
          'path': path.relative(entity.path, from: storagePath),
          'isDirectory': entity is Directory,
          'size': fileSize,
          'itemCount': itemCount, // Add item count for directories
          'modified': stat.modified.toIso8601String(),
          'type': entity is Directory ? 'folder' : _getFileType(fileName),
        };

        fileList.add(fileInfo);
      }

      // Sort: directories first, then files alphabetically
      fileList.sort((a, b) {
        if (a['isDirectory'] && !b['isDirectory']) return -1;
        if (!a['isDirectory'] && b['isDirectory']) return 1;
        return a['name']
            .toString()
            .toLowerCase()
            .compareTo(b['name'].toString().toLowerCase());
      });

      return fileList;
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> handleFileUpload(
      HttpRequest request, String boundary) async {
    try {
      final bodyBytes = await request.fold<List<int>>(
          [], (previous, element) => previous..addAll(element));

      if (bodyBytes.isEmpty) {
        return {'success': false, 'message': 'No data received'};
      }

      final multipartData = await _parseMultipartData(bodyBytes, boundary);

      if (multipartData == null) {
        return {'success': false, 'message': 'Invalid multipart data'};
      }

      final fileName = multipartData['filename'];
      final fileData = multipartData['data'];
      final targetPath = multipartData['path'] ?? '';

      if (fileName == null || fileData == null) {
        return {'success': false, 'message': 'Missing file data'};
      }

      // Create target directory
      final fullTargetPath = path.join(storagePath, targetPath);
      await Directory(fullTargetPath).create(recursive: true);

      // Save file
      final filePath = path.join(fullTargetPath, fileName);
      final file = File(filePath);

      await file.writeAsBytes(fileData);

      return {
        'success': true,
        'message': 'File uploaded successfully',
        'fileName': fileName,
        'size': fileData.length,
      };
    } catch (e) {
      print('Upload error: $e');
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  Future<Map<String, dynamic>?> _parseMultipartData(
      List<int> data, String boundary) async {
    try {
      final dataString = String.fromCharCodes(data);

      // Find file data section
      final parts = dataString.split('--$boundary');

      for (final part in parts) {
        if (part.contains('Content-Disposition: form-data') &&
            part.contains('filename=')) {
          // Extract filename
          final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(part);
          if (filenameMatch == null) continue;

          final filename = filenameMatch.group(1);

          // Extract file data (after double CRLF)
          final headerEndIndex = part.indexOf('\r\n\r\n');
          if (headerEndIndex == -1) continue;

          final fileDataStart = headerEndIndex + 4;
          final fileDataEnd = part.length - 2; // Remove trailing CRLF

          if (fileDataStart >= fileDataEnd) continue;

          final fileDataString = part.substring(fileDataStart, fileDataEnd);
          final fileData = utf8.encode(fileDataString);

          // Extract path if present
          String? targetPath;
          final pathMatch = RegExp(r'name="path"[^>]*\r\n\r\n([^\r\n]*)')
              .firstMatch(dataString);
          if (pathMatch != null) {
            targetPath = pathMatch.group(1);
          }

          return {
            'filename': filename,
            'data': fileData,
            'path': targetPath,
          };
        }
      }

      return null;
    } catch (e) {
      print('Multipart parsing error: $e');
      return null;
    }
  }

  Future<bool> createFolder(String folderName, String parentPath) async {
    try {
      final fullPath = path.join(storagePath, parentPath, folderName);
      final directory = Directory(fullPath);

      if (directory.existsSync()) {
        return false; // Folder already exists
      }

      await directory.create(recursive: true);
      return true;
    } catch (e) {
      print('Error creating folder: $e');
      return false;
    }
  }

  Future<bool> deleteFile(String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final entity = File(fullPath);

      if (entity.existsSync()) {
        await entity.delete();
        return true;
      }

      // Try as directory
      final directory = Directory(fullPath);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
        return true;
      }

      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  Future<void> serveFileDownload(
      HttpRequest request, String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('File not found');
        return;
      }

      final stat = await file.stat();
      final fileName = path.basename(file.path);

      // Set headers for download
      request.response.headers.set('Content-Type', 'application/octet-stream');
      request.response.headers
          .set('Content-Disposition', 'attachment; filename="$fileName"');
      request.response.headers.set('Content-Length', stat.size.toString());

      // Stream file content
      await file.openRead().pipe(request.response);
    } catch (e) {
      print('Download error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Download failed');
    }
  }

  Future<List<Map<String, dynamic>>> searchFiles(
      String query, String? fileType) async {
    try {
      final results = <Map<String, dynamic>>[];

      await _searchInDirectory(
          Directory(storagePath), query.toLowerCase(), fileType, results);

      return results;
    } catch (e) {
      print('Search error: $e');
      return [];
    }
  }

  Future<void> _searchInDirectory(Directory directory, String query,
      String? fileType, List<Map<String, dynamic>> results) async {
    try {
      await for (final entity in directory.list()) {
        final fileName = path.basename(entity.path);

        // Skip hidden files
        if (fileName.startsWith('.')) continue;

        if (entity is Directory) {
          // Search in subdirectory
          await _searchInDirectory(entity, query, fileType, results);
        } else if (entity is File) {
          // Check if file matches search criteria
          final matchesName = fileName.toLowerCase().contains(query);
          final matchesType =
              fileType == null || _getFileType(fileName) == fileType;

          if (matchesName && matchesType) {
            final stat = await entity.stat();

            results.add({
              'name': fileName,
              'path': path.relative(entity.path, from: storagePath),
              'isDirectory': false,
              'size': stat.size,
              'modified': stat.modified.toIso8601String(),
              'type': _getFileType(fileName),
            });
          }
        }
      }
    } catch (e) {
      print('Error searching in directory ${directory.path}: $e');
    }
  }

  Future<int> getTotalFiles() async {
    try {
      int count = 0;
      await _countFilesInDirectory(
          Directory(storagePath), (fileCount) => count = fileCount);
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _countFilesInDirectory(
      Directory directory, Function(int) updateCount) async {
    try {
      int count = 0;

      await for (final entity in directory.list()) {
        if (entity is File && !path.basename(entity.path).startsWith('.')) {
          count++;
        } else if (entity is Directory &&
            !path.basename(entity.path).startsWith('.')) {
          await _countFilesInDirectory(entity, (subCount) => count += subCount);
        }
      }

      updateCount(count);
    } catch (e) {
      updateCount(0);
    }
  }

  Future<int> getStorageUsed() async {
    try {
      int totalSize = 0;
      await _calculateDirectorySize(
          Directory(storagePath), (size) => totalSize = size);
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _calculateDirectorySize(
      Directory directory, Function(int) updateSize) async {
    try {
      int totalSize = 0;

      await for (final entity in directory.list()) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        } else if (entity is Directory) {
          await _calculateDirectorySize(
              entity, (subSize) => totalSize += subSize);
        }
      }

      updateSize(totalSize);
    } catch (e) {
      updateSize(0);
    }
  }

  String _getFileType(String fileName) {
    final ext = path.extension(fileName).toLowerCase().replaceFirst('.', '');

    // Video files - Comprehensive list
    if ([
      // Common video formats
      'mp4', 'avi', 'mkv', 'mov', 'webm', 'm4v', 'flv', 'wmv',
      // Additional video formats
      'ogv', '3gp', '3g2', 'ts', 'mts', 'm2ts', 'asf', 'rm', 'rmvb',
      'divx', 'xvid', 'vob', 'f4v', 'm2v', 'mpg', 'mpeg', 'mpe', 'mpv',
      'qt', 'swf', 'yuv', 'webmv', 'dv', 'dat', 'nsv', 'mka'
    ].contains(ext)) {
      return 'video';
    }

    // Audio files - Comprehensive list
    if ([
      // Common audio formats
      'mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg', 'wma', 'oga', 'opus',
      // Additional audio formats
      'ac3', 'au', 'aiff', 'aif', 'aifc', 'amr', 'awb', 'dts', 'dtshd',
      'ra', 'ram', 'ape', 'caf', 'mid', 'midi', 'kar', 'gsm', '3ga',
      'mp2', 'mpa'
    ].contains(ext)) {
      return 'audio';
    }

    // Image files - Comprehensive list
    if ([
      // Common image formats
      'jpg', 'jpeg', 'jpe', 'jfif', 'png', 'gif', 'webp', 'svg', 'svgz',
      'bmp', 'dib', 'ico', 'cur', 'tiff', 'tif',
      // Professional formats
      'psd', 'ai', 'eps', 'ps', 'pcx', 'tga', 'jp2', 'jpx', 'jpm', 'mj2',
      'xbm', 'xpm', 'pbm', 'pgm', 'ppm', 'pnm', 'ras', 'sgi', 'jng', 'wbmp',
      // RAW camera formats
      'cr2', 'crw', 'nef', 'orf', 'raf', 'rw2', 'srw', 'arw', 'dng', 'pef',
      'x3f', 'raw', 'dcr', 'kdc', 'erf', 'mef', 'mrw', '3fr', 'fff', 'iiq',
      'k25', 'rwl', 'dcs',
      // Modern formats
      'avif', 'heic', 'heif'
    ].contains(ext)) {
      return 'image';
    }

    // Document files
    if ([
      'pdf',
      'doc',
      'docx',
      'txt',
      'rtf',
      'odt',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'md',
      'log',
      'ini',
      'cfg',
      'conf'
    ].contains(ext)) {
      return 'document';
    }

    // Archive files
    if (['zip', 'rar', '7z', 'tar', 'gz', 'bz2', 'xz'].contains(ext)) {
      return 'archive';
    }

    // Code files
    if ([
      'js',
      'html',
      'htm',
      'css',
      'dart',
      'py',
      'java',
      'cpp',
      'c',
      'cs',
      'php',
      'json',
      'xml'
    ].contains(ext)) {
      return 'code';
    }

    return 'file';
  }

  // Add file path without copying (for link mode)
  Future<bool> addFilePath(String originalPath, String displayName) async {
    try {
      if (!File(originalPath).existsSync()) {
        return false;
      }

      filePaths.add(originalPath);

      // Create a symlink or reference file
      final referencePath = path.join(storagePath, '$displayName.udrive_link');
      final referenceFile = File(referencePath);

      await referenceFile.writeAsString(jsonEncode({
        'type': 'file_link',
        'originalPath': originalPath,
        'displayName': displayName,
        'created': DateTime.now().toIso8601String(),
      }));

      return true;
    } catch (e) {
      print('Error adding file path: $e');
      return false;
    }
  }

  // Handle UDrive link files
  Future<String?> resolveFileLink(String linkPath) async {
    try {
      final linkFile = File(linkPath);
      if (!linkFile.existsSync() || !linkPath.endsWith('.udrive_link')) {
        return null;
      }

      final content = await linkFile.readAsString();
      final data = jsonDecode(content);

      final originalPath = data['originalPath'];
      if (originalPath != null && File(originalPath).existsSync()) {
        return originalPath;
      }

      return null;
    } catch (e) {
      print('Error resolving file link: $e');
      return null;
    }
  }
}
