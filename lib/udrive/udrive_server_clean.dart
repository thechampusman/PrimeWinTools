import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'media_streamer.dart';

class UDriveServer {
  static const String version = '1.0.0';

  HttpServer? _server;
  late UDriveFileManager fileManager;
  late UDriveMediaStreamer mediaStreamer;

  String storagePath = '';
  int port = 8080;
  bool isRunning = false;
  String? serverUrl;

  // Server statistics
  int totalConnections = 0;
  int activeConnections = 0;
  DateTime? startTime;

  UDriveServer({this.port = 8080}) {
    fileManager = UDriveFileManager();
    mediaStreamer = UDriveMediaStreamer();
  }

  Future<bool> startServer({String? customStoragePath}) async {
    try {
      if (isRunning) {
        print('UDrive server is already running');
        return false;
      }

      // Set storage path
      if (customStoragePath != null) {
        storagePath = customStoragePath;
      } else {
        storagePath = path.join(
            Platform.environment['USERPROFILE'] ?? '', 'Documents', 'UDrive');
      }

      // Ensure storage directory exists
      await Directory(storagePath).create(recursive: true);
      fileManager.setStoragePath(storagePath);
      mediaStreamer.setStoragePath(storagePath);

      // Start HTTP server on localhost only
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _server!.autoCompress = true;

      // Set up request handling
      _server!.listen(_handleRequest);

      isRunning = true;
      startTime = DateTime.now();
      serverUrl = 'http://localhost:$port';

      print('🚀 UDrive Server started successfully!');
      print('📁 Storage Path: $storagePath');
      print('🌐 Server URL: $serverUrl');
      print('💻 Local access only');

      return true;
    } catch (e) {
      print('❌ Failed to start UDrive server: $e');
      return false;
    }
  }

  Future<void> stopServer() async {
    if (_server != null) {
      await _server!.close();
      _server = null;
      isRunning = false;
      startTime = null;
      print('🛑 UDrive Server stopped');
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      totalConnections++;
      activeConnections++;

      final uri = request.uri;
      final method = request.method;

      print(
          '📡 $method ${uri.path} from ${request.connectionInfo?.remoteAddress}');

      // Add CORS headers
      _addCorsHeaders(request.response);

      // Handle preflight requests
      if (method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.ok;
        await request.response.close();
        return;
      }

      // Route requests
      if (uri.path == '/') {
        await _serveMainPage(request);
      } else if (uri.path.startsWith('/api/')) {
        await _handleApiRequest(request);
      } else if (uri.path.startsWith('/stream/')) {
        await _handleStreamRequest(request);
      } else if (uri.path.startsWith('/download/')) {
        await _handleDownloadRequest(request);
      } else if (uri.path.startsWith('/css/') ||
          uri.path.startsWith('/js/') ||
          uri.path.startsWith('/assets/')) {
        await _serveStaticAsset(request);
      } else {
        await _serve404(request);
      }
    } catch (e) {
      print('❌ Error handling request: $e');
      await _serveError(request, 'Internal server error');
    } finally {
      activeConnections--;
    }
  }

  Future<void> _handleApiRequest(HttpRequest request) async {
    final path = request.uri.path;

    switch (path) {
      case '/api/files':
        if (request.method == 'GET') {
          await _handleGetFiles(request);
        }
        break;
      case '/api/upload':
        if (request.method == 'POST') {
          await _handleUploadFile(request);
        }
        break;
      case '/api/folder':
        if (request.method == 'POST') {
          await _handleCreateFolder(request);
        }
        break;
      case '/api/delete':
        if (request.method == 'DELETE') {
          await _handleDeleteFile(request);
        }
        break;
      case '/api/info':
        if (request.method == 'GET') {
          await _handleServerInfo(request);
        }
        break;
      case '/api/search':
        if (request.method == 'GET') {
          await _handleSearch(request);
        }
        break;
      case '/api/download':
        if (request.method == 'GET') {
          await _handleDownloadFile(request);
        }
        break;
      case '/api/move':
        if (request.method == 'POST') {
          await _handleMoveFile(request);
        }
        break;
      case '/api/copy':
        if (request.method == 'POST') {
          await _handleCopyFile(request);
        }
        break;
      case '/api/rename':
        if (request.method == 'POST') {
          await _handleRenameFile(request);
        }
        break;
      default:
        await _serve404(request);
    }
  }

  Future<void> _serveMainPage(HttpRequest request) async {
    try {
      final htmlContent = await _loadHtmlFile();
      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      _addCorsHeaders(request.response);
      request.response.write(htmlContent);
      await request.response.close();
    } catch (e) {
      print('❌ Error serving main page: $e');
      await _serveError(request, 'Error loading main page');
    }
  }

  Future<void> _serveStaticAsset(HttpRequest request) async {
    try {
      final assetPath = request.uri.path.substring(1); // Remove leading /
      print('🎨 Serving static asset: ${request.uri.path} -> $assetPath');

      String assetFilePath;

      // Handle different static file paths
      if (request.uri.path.startsWith('/assets/')) {
        assetFilePath = request.uri.path.replaceFirst('/assets/', '');
      } else if (request.uri.path.startsWith('/css/')) {
        assetFilePath = 'css/${request.uri.path.replaceFirst('/css/', '')}';
      } else if (request.uri.path.startsWith('/js/')) {
        assetFilePath = 'js/${request.uri.path.replaceFirst('/js/', '')}';
      } else {
        assetFilePath = request.uri.path.substring(1); // Remove leading slash
      }

      final content = await _loadStaticAsset(assetFilePath);
      if (content != null) {
        // Set appropriate content type
        if (assetFilePath.endsWith('.css')) {
          request.response.headers.contentType =
              ContentType('text', 'css', charset: 'utf-8');
        } else if (assetFilePath.endsWith('.js')) {
          request.response.headers.contentType =
              ContentType('application', 'javascript', charset: 'utf-8');
        }

        _addCorsHeaders(request.response);
        request.response.write(content);
        print(
            '✅ Successfully served static asset: $assetFilePath (${content.length} characters)');
        await request.response.close();
      } else {
        await _serve404(request);
      }
    } catch (e) {
      print('❌ Error serving static asset: $e');
      await _serve404(request);
    }
  }

  Future<void> _handleGetFiles(HttpRequest request) async {
    print('🔍 _handleGetFiles method called');
    try {
      final queryParams = request.uri.queryParameters;
      final folderPath = queryParams['path'] ?? '';

      print('📂 API /api/files called with path: "$folderPath"');
      print('🔍 Query parameters: $queryParams');
      print('🔍 Full request URI: ${request.uri}');

      print('🔍 Calling fileManager.getFiles("$folderPath")...');
      final files = await fileManager.getFiles(folderPath);
      print('🔍 fileManager.getFiles returned successfully');
      print('🔍 Files type: ${files.runtimeType}');
      print('🔍 Files length: ${files.length}');

      print('📊 Found ${files.length} files in folder: "$folderPath"');
      if (files.isNotEmpty) {
        print('📁 Files found:');
        for (int i = 0; i < (files.length > 10 ? 10 : files.length); i++) {
          final file = files[i];
          print('   - ${file['name']} (${file['type']}) - ${file['size']}');
        }
        if (files.length > 10) {
          print('   ... and ${files.length - 10} more files');
        }
      } else {
        print('📭 No files found in folder: "$folderPath"');
      }

      print('🔍 Building response data...');
      final responseData = {
        'success': true,
        'files': files,
        'currentPath': folderPath,
        'serverInfo': {
          'version': version,
          'uptime': startTime != null
              ? DateTime.now().difference(startTime!).inSeconds
              : 0,
          'totalConnections': totalConnections,
          'activeConnections': activeConnections,
        }
      };
      print('🔍 Response data built successfully');
      print(
          '🔍 Response data structure: success=${responseData['success']}, files count=${(responseData['files'] as List).length}');

      print('🔍 Adding CORS headers...');
      _addCorsHeaders(request.response);
      print('🔍 CORS headers added');

      print('🔍 Sending JSON response...');
      _sendJsonResponse(request.response, responseData);
      print('🔍 _sendJsonResponse called successfully');

      print(
          '✅ API /api/files response sent successfully with ${files.length} files');
    } catch (e, stackTrace) {
      print('❌ Error in _handleGetFiles: $e');
      print('❌ Stack trace: $stackTrace');
      try {
        _addCorsHeaders(request.response);
        _sendJsonError(request.response, 'Failed to get files: $e');
        print('🔍 Error response sent');
      } catch (errorSendingError) {
        print('❌ Error sending error response: $errorSendingError');
      }
    }
  }

  Future<void> _handleUploadFile(HttpRequest request) async {
    try {
      final boundary = request.headers.contentType?.parameters['boundary'];
      if (boundary == null) {
        _sendJsonError(request.response, 'Missing boundary in content type');
        return;
      }

      final result = await fileManager.handleFileUpload(request, boundary);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error uploading file: $e');
      _sendJsonError(request.response, 'Upload failed: $e');
    }
  }

  Future<void> _handleCreateFolder(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final folderName = data['name'];
      final parentPath = data['path'] ?? '';

      final result = await fileManager.createFolder(folderName, parentPath);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error creating folder: $e');
      _sendJsonError(request.response, 'Failed to create folder: $e');
    }
  }

  Future<void> _handleDeleteFile(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final filePath = queryParams['path'];

      if (filePath == null) {
        _sendJsonError(request.response, 'File path is required');
        return;
      }

      final result = await fileManager.deleteFile(filePath);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error deleting file: $e');
      _sendJsonError(request.response, 'Failed to delete file: $e');
    }
  }

  Future<void> _handleServerInfo(HttpRequest request) async {
    final networkInfo = await _getNetworkInfo();

    _sendJsonResponse(request.response, {
      'success': true,
      'server': {
        'name': 'UDrive Personal Cloud',
        'version': version,
        'uptime': startTime != null
            ? DateTime.now().difference(startTime!).inSeconds
            : 0,
        'port': port,
        'storagePath': storagePath,
      },
      'stats': {
        'totalConnections': totalConnections,
        'activeConnections': activeConnections,
        'totalFiles': await fileManager.getTotalFiles(),
        'storageUsed': await fileManager.getStorageUsed(),
      },
      'network': networkInfo,
    });
  }

  Future<void> _handleSearch(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final query = queryParams['q'] ?? '';
      final type = queryParams['type'];

      if (query.isEmpty) {
        _sendJsonError(request.response, 'Search query is required');
        return;
      }

      final results = await fileManager.searchFiles(query, type);
      _sendJsonResponse(request.response, {
        'success': true,
        'results': results,
        'query': query,
        'type': type,
      });
    } catch (e) {
      print('❌ Error searching files: $e');
      _sendJsonError(request.response, 'Search failed: $e');
    }
  }

  Future<void> _handleDownloadFile(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final filePath = queryParams['path'];

      if (filePath == null) {
        _sendJsonError(request.response, 'File path is required');
        return;
      }

      print('📥 Download request for: $filePath');
      await fileManager.serveFileDownload(request, filePath);
    } catch (e) {
      print('❌ Error downloading file: $e');
      _sendJsonError(request.response, 'Download failed: $e');
    }
  }

  Future<void> _handleMoveFile(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final sourcePath = data['source'];
      final targetPath = data['target'];

      if (sourcePath == null || targetPath == null) {
        _sendJsonError(
            request.response, 'Source and target paths are required');
        return;
      }

      print('📦 Moving file from: $sourcePath to: $targetPath');
      final result = await fileManager.moveFile(sourcePath, targetPath);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error moving file: $e');
      _sendJsonError(request.response, 'Move failed: $e');
    }
  }

  Future<void> _handleCopyFile(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final sourcePath = data['source'];
      final targetPath = data['target'];

      if (sourcePath == null || targetPath == null) {
        _sendJsonError(
            request.response, 'Source and target paths are required');
        return;
      }

      print('📋 Copying file from: $sourcePath to: $targetPath');
      final result = await fileManager.copyFile(sourcePath, targetPath);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error copying file: $e');
      _sendJsonError(request.response, 'Copy failed: $e');
    }
  }

  Future<void> _handleRenameFile(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final filePath = data['path'];
      final newName = data['name'];

      if (filePath == null || newName == null) {
        _sendJsonError(request.response, 'File path and new name are required');
        return;
      }

      print('✏️ Renaming file: $filePath to: $newName');
      final result = await fileManager.renameFile(filePath, newName);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      print('❌ Error renaming file: $e');
      _sendJsonError(request.response, 'Rename failed: $e');
    }
  }

  Future<void> _handleStreamRequest(HttpRequest request) async {
    try {
      final filePath = request.uri.path.substring('/stream/'.length);
      await mediaStreamer.streamFile(request, filePath);
    } catch (e) {
      print('❌ Error streaming file: $e');
      await _serve404(request);
    }
  }

  Future<void> _handleDownloadRequest(HttpRequest request) async {
    try {
      final filePath = request.uri.path.substring('/download/'.length);
      await fileManager.serveFileDownload(request, filePath);
    } catch (e) {
      print('❌ Error downloading file: $e');
      await _serve404(request);
    }
  }

  Future<String> _loadHtmlFile() async {
    final possiblePaths = [
      path.join(
          Directory.current.path, 'lib', 'udrive', 'web_assets', 'index.html'),
      path.join(Directory.current.path, '..', '..', 'lib', 'udrive',
          'web_assets', 'index.html'),
      path.join('D:', 'PersonalProjects', 'PrimeWinTools', 'lib', 'udrive',
          'web_assets', 'index.html'),
      path.join('lib', 'udrive', 'web_assets', 'index.html'),
    ];

    print('🔍 Current directory: ${Directory.current.path}');

    for (final htmlPath in possiblePaths) {
      print('🔍 Trying HTML path: $htmlPath');
      final htmlFile = File(htmlPath);

      if (htmlFile.existsSync()) {
        final content = await htmlFile.readAsString();
        print('✅ Successfully loaded HTML file from: $htmlPath');
        print('✅ Content length: ${content.length} characters');
        return content;
      } else {
        print('❌ HTML file does not exist: $htmlPath');
      }
    }

    // Return minimal error page if file not found
    print('❌ CRITICAL: Could not load index.html file from any location!');
    return '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UDrive - Files Not Found</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; margin: 0; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #e74c3c; margin-bottom: 20px; }
        p { color: #666; margin-bottom: 30px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>UDrive Files Not Found</h1>
        <p>Could not load the main interface. Please check that web_assets/index.html exists.</p>
        <p>Current directory: ${Directory.current.path}</p>
    </div>
</body>
</html>''';
  }

  Future<String?> _loadStaticAsset(String assetPath) async {
    final possiblePaths = [
      path.join(
          Directory.current.path, 'lib', 'udrive', 'web_assets', assetPath),
      path.join(Directory.current.path, '..', '..', 'lib', 'udrive',
          'web_assets', assetPath),
      path.join('D:', 'PersonalProjects', 'PrimeWinTools', 'lib', 'udrive',
          'web_assets', assetPath),
      path.join('lib', 'udrive', 'web_assets', assetPath),
    ];

    try {
      print(
          '🔍 Loading asset: $assetPath from current directory: ${Directory.current.path}');

      for (final assetFilePath in possiblePaths) {
        print('🔍 Trying asset path: $assetFilePath');
        final assetFile = File(assetFilePath);
        if (assetFile.existsSync()) {
          final content = await assetFile.readAsString();
          print(
              '✅ Successfully loaded asset from: $assetFilePath (${content.length} characters)');
          return content;
        }
      }

      print('❌ Asset file not found: $assetPath');
      return null;
    } catch (e) {
      print('❌ Error loading asset $assetPath: $e');
      return null;
    }
  }

  Future<void> _serve404(HttpRequest request) async {
    try {
      request.response.statusCode = HttpStatus.notFound;
      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      _addCorsHeaders(request.response);

      final htmlContent = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Not Found | UDrive</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #e74c3c; margin-bottom: 20px; }
        p { color: #666; margin-bottom: 30px; }
        a { color: #3498db; text-decoration: none; padding: 10px 20px; background: #ecf0f1; border-radius: 5px; }
        a:hover { background: #d5dbdb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>404 - Not Found</h1>
        <p>The requested resource could not be found.</p>
        <a href="/">← Back to UDrive</a>
    </div>
</body>
</html>''';
      request.response.write(htmlContent);
      await request.response.close();
    } catch (e) {
      print('❌ Error serving 404 page: $e');
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('404 - Not Found');
      await request.response.close();
    }
  }

  Future<void> _serveError(HttpRequest request, String message) async {
    try {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType =
          ContentType('text', 'html', charset: 'utf-8');
      _addCorsHeaders(request.response);

      final htmlContent = '''<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Server Error | UDrive</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; background: #f5f5f5; margin: 0; }
        .container { max-width: 500px; margin: 0 auto; background: white; padding: 40px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        h1 { color: #e74c3c; margin-bottom: 20px; }
        p { color: #666; margin-bottom: 30px; }
        a { color: #3498db; text-decoration: none; padding: 10px 20px; background: #ecf0f1; border-radius: 5px; }
        a:hover { background: #d5dbdb; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Server Error</h1>
        <p>$message</p>
        <a href="/">← Back to UDrive</a>
    </div>
</body>
</html>''';
      request.response.write(htmlContent);
      await request.response.close();
    } catch (e) {
      print('❌ Error serving error page: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  Future<Map<String, dynamic>> _getNetworkInfo() async {
    return {
      'interfaces': [
        {
          'interface': 'localhost',
          'ip': '127.0.0.1',
          'url': 'http://localhost:$port',
          'isPrivate': true,
          'isPrimary': true,
        }
      ],
      'primaryUrl': 'http://localhost:$port',
      'autoDetected': true,
    };
  }

  void _addCorsHeaders(HttpResponse response) {
    response.headers.add('Access-Control-Allow-Origin', '*');
    response.headers
        .add('Access-Control-Allow-Methods', 'GET, POST, DELETE, OPTIONS');
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  }

  void _sendJsonResponse(HttpResponse response, Map<String, dynamic> data) {
    try {
      print('🔍 _sendJsonResponse called');
      response.headers.contentType = ContentType.json;
      final jsonString = jsonEncode(data);
      print('📤 Sending JSON response (${jsonString.length} characters)');
      if (data.containsKey('files')) {
        print('📦 Response contains ${data['files']?.length ?? 0} files');
      }
      print('🔍 Writing response data...');
      response.write(jsonString);
      print('🔍 Closing response...');
      response.close();
      print('✅ JSON response sent and closed successfully');
    } catch (e, stackTrace) {
      print('❌ Error in _sendJsonResponse: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  void _sendJsonError(HttpResponse response, String message) {
    try {
      print('🔍 _sendJsonError called with message: $message');
      response.statusCode = HttpStatus.badRequest;
      response.headers.contentType = ContentType.json;
      final errorData = {
        'success': false,
        'error': message,
      };
      final jsonString = jsonEncode(errorData);
      print('📤 Sending error response (${jsonString.length} characters)');
      response.write(jsonString);
      print('🔍 Closing error response...');
      response.close();
      print('✅ Error response sent and closed successfully');
    } catch (e, stackTrace) {
      print('❌ Error in _sendJsonError: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }
}

// File Manager Class (Clean implementation without embedded content)
class UDriveFileManager {
  String _storagePath = '';

  void setStoragePath(String path) {
    _storagePath = path;
    print('📁 FileManager storage path set to: $_storagePath');
  }

  String get storagePath => _storagePath;

  Future<List<Map<String, dynamic>>> getFiles(String relativePath) async {
    try {
      // Normalize the relative path - empty string or "/" should stay in storage path
      String normalizedPath = relativePath.trim();
      if (normalizedPath == '/' || normalizedPath == '\\') {
        normalizedPath = '';
      }

      // Remove leading slashes to prevent path.join from treating it as absolute
      if (normalizedPath.startsWith('/') || normalizedPath.startsWith('\\')) {
        normalizedPath = normalizedPath.substring(1);
      }

      final fullPath = normalizedPath.isEmpty
          ? _storagePath
          : path.join(_storagePath, normalizedPath);
      print('🔍 Resolved path: "$relativePath" -> "$fullPath"');

      final directory = Directory(fullPath);

      if (!directory.existsSync()) {
        print('📁 Directory does not exist: $fullPath');
        return [];
      }

      final files = <Map<String, dynamic>>[];

      await for (final entity in directory.list()) {
        try {
          final stat = await entity.stat();
          final name = path.basename(entity.path);

          // Skip hidden files and system files
          if (name.startsWith('.')) continue;

          if (entity is Directory) {
            files.add({
              'name': name,
              'type': 'folder',
              'size': 0,
              'modified': stat.modified.toIso8601String(),
              'path': path
                  .relative(entity.path, from: _storagePath)
                  .replaceAll('\\', '/'),
            });
          } else if (entity is File) {
            files.add({
              'name': name,
              'type': _getFileType(name),
              'size': stat.size,
              'modified': stat.modified.toIso8601String(),
              'path': path
                  .relative(entity.path, from: _storagePath)
                  .replaceAll('\\', '/'),
              'extension': path.extension(name).toLowerCase(),
            });
          }
        } catch (e) {
          print('⚠️ Error processing file ${entity.path}: $e');
        }
      }

      // Sort files: folders first, then alphabetically
      files.sort((a, b) {
        if (a['type'] == 'folder' && b['type'] != 'folder') return -1;
        if (a['type'] != 'folder' && b['type'] == 'folder') return 1;
        return a['name']
            .toString()
            .toLowerCase()
            .compareTo(b['name'].toString().toLowerCase());
      });

      return files;
    } catch (e) {
      print('❌ Error getting files from $_storagePath/$relativePath: $e');
      return [];
    }
  }

  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    final imageExts = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.svg'
    ];
    final videoExts = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm'];
    final audioExts = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a'];
    final documentExts = ['.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt'];
    final archiveExts = ['.zip', '.rar', '.7z', '.tar', '.gz'];

    if (imageExts.contains(extension)) return 'image';
    if (videoExts.contains(extension)) return 'video';
    if (audioExts.contains(extension)) return 'audio';
    if (documentExts.contains(extension)) return 'document';
    if (archiveExts.contains(extension)) return 'archive';

    return 'file';
  }

  Future<Map<String, dynamic>> handleFileUpload(
      HttpRequest request, String boundary) async {
    try {
      // Simplified upload handler - reads request stream directly
      final bytes =
          await request.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));

      // Extract filename from Content-Disposition header (simplified)
      final contentDisposition =
          request.headers.value('content-disposition') ?? '';
      final filenameMatch =
          RegExp(r'filename="([^"]*)"').firstMatch(contentDisposition);
      final filename = filenameMatch?.group(1) ??
          'uploaded_file_${DateTime.now().millisecondsSinceEpoch}';

      final filePath = path.join(_storagePath, filename);
      final file = File(filePath);

      // Create directory if it doesn't exist
      await file.parent.create(recursive: true);

      await file.writeAsBytes(bytes);

      print('✅ File uploaded: $filename to ${file.path}');

      return {
        'success': true,
        'fileName': filename,
        'size': bytes.length,
        'path': '',
      };
    } catch (e) {
      print('❌ Upload error: $e');
      return {'success': false, 'message': 'Upload failed: $e'};
    }
  }

  Future<Map<String, dynamic>> createFolder(
      String folderName, String parentPath) async {
    try {
      final fullPath = path.join(_storagePath, parentPath, folderName);
      final directory = Directory(fullPath);

      if (directory.existsSync()) {
        return {'success': false, 'message': 'Folder already exists'};
      }

      await directory.create(recursive: true);

      return {
        'success': true,
        'folderName': folderName,
        'path':
            path.relative(fullPath, from: _storagePath).replaceAll('\\', '/'),
      };
    } catch (e) {
      print('❌ Error creating folder: $e');
      return {'success': false, 'message': 'Failed to create folder: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteFile(String filePath) async {
    try {
      final fullPath = path.join(_storagePath, filePath);
      final entity = FileSystemEntity.typeSync(fullPath);

      if (entity == FileSystemEntityType.notFound) {
        return {'success': false, 'message': 'File not found'};
      }

      if (entity == FileSystemEntityType.directory) {
        await Directory(fullPath).delete(recursive: true);
      } else {
        await File(fullPath).delete();
      }

      return {'success': true, 'message': 'File deleted successfully'};
    } catch (e) {
      print('❌ Error deleting file: $e');
      return {'success': false, 'message': 'Failed to delete file: $e'};
    }
  }

  Future<int> getTotalFiles() async {
    try {
      int count = 0;
      await for (final entity
          in Directory(_storagePath).list(recursive: true)) {
        if (entity is File) count++;
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getStorageUsed() async {
    try {
      int totalSize = 0;
      await for (final entity
          in Directory(_storagePath).list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> searchFiles(
      String query, String? type) async {
    try {
      final results = <Map<String, dynamic>>[];

      await for (final entity
          in Directory(_storagePath).list(recursive: true)) {
        if (entity is File) {
          final name = path.basename(entity.path);

          // Skip hidden files
          if (name.startsWith('.')) continue;

          // Check if name matches query
          if (!name.toLowerCase().contains(query.toLowerCase())) continue;

          // Check type filter if specified
          if (type != null && type.isNotEmpty && type != 'all') {
            final fileType = _getFileType(name);
            if (fileType != type) continue;
          }

          final stat = await entity.stat();
          results.add({
            'name': name,
            'type': _getFileType(name),
            'size': stat.size,
            'modified': stat.modified.toIso8601String(),
            'path': path
                .relative(entity.path, from: _storagePath)
                .replaceAll('\\', '/'),
            'extension': path.extension(name).toLowerCase(),
          });
        }
      }

      return results;
    } catch (e) {
      print('❌ Error searching files: $e');
      return [];
    }
  }

  Future<void> serveFileDownload(HttpRequest request, String filePath) async {
    try {
      final fullPath = path.join(_storagePath, filePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        request.response.statusCode = 404;
        request.response.write('File not found');
        await request.response.close();
        return;
      }

      final fileName = path.basename(filePath);
      final mimeType = _getMimeType(path.extension(fileName));

      request.response.headers.set('content-type', mimeType);
      request.response.headers
          .set('content-disposition', 'attachment; filename="$fileName"');

      await file.openRead().pipe(request.response);
    } catch (e) {
      print('❌ Error serving file download: $e');
      request.response.statusCode = 500;
      request.response.write('Error serving file');
      await request.response.close();
    }
  }

  String _getMimeType(String extension) {
    final mimeTypes = {
      '.txt': 'text/plain',
      '.html': 'text/html',
      '.css': 'text/css',
      '.js': 'application/javascript',
      '.json': 'application/json',
      '.pdf': 'application/pdf',
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.gif': 'image/gif',
      '.svg': 'image/svg+xml',
      '.mp4': 'video/mp4',
      '.mp3': 'audio/mpeg',
      '.zip': 'application/zip',
    };

    return mimeTypes[extension.toLowerCase()] ?? 'application/octet-stream';
  }

  Future<Map<String, dynamic>> moveFile(
      String sourcePath, String targetPath) async {
    try {
      final sourceFullPath = path.join(_storagePath, sourcePath);
      final targetFullPath = path.join(_storagePath, targetPath);

      final sourceFile = File(sourceFullPath);
      final sourceDir = Directory(sourceFullPath);

      if (sourceFile.existsSync()) {
        await sourceFile.rename(targetFullPath);
        print('✅ File moved: $sourcePath -> $targetPath');
      } else if (sourceDir.existsSync()) {
        await sourceDir.rename(targetFullPath);
        print('✅ Directory moved: $sourcePath -> $targetPath');
      } else {
        return {
          'success': false,
          'error': 'Source file or directory not found: $sourcePath'
        };
      }

      return {
        'success': true,
        'message': 'File moved successfully',
        'source': sourcePath,
        'target': targetPath
      };
    } catch (e) {
      print('❌ Error moving file: $e');
      return {'success': false, 'error': 'Failed to move file: $e'};
    }
  }

  Future<Map<String, dynamic>> copyFile(
      String sourcePath, String targetPath) async {
    try {
      final sourceFullPath = path.join(_storagePath, sourcePath);
      final targetFullPath = path.join(_storagePath, targetPath);

      final sourceFile = File(sourceFullPath);
      final sourceDir = Directory(sourceFullPath);

      if (sourceFile.existsSync()) {
        await sourceFile.copy(targetFullPath);
        print('✅ File copied: $sourcePath -> $targetPath');
      } else if (sourceDir.existsSync()) {
        await _copyDirectory(sourceDir, Directory(targetFullPath));
        print('✅ Directory copied: $sourcePath -> $targetPath');
      } else {
        return {
          'success': false,
          'error': 'Source file or directory not found: $sourcePath'
        };
      }

      return {
        'success': true,
        'message': 'File copied successfully',
        'source': sourcePath,
        'target': targetPath
      };
    } catch (e) {
      print('❌ Error copying file: $e');
      return {'success': false, 'error': 'Failed to copy file: $e'};
    }
  }

  Future<void> _copyDirectory(Directory source, Directory target) async {
    await target.create(recursive: true);

    await for (final entity in source.list(recursive: false)) {
      if (entity is File) {
        final newFile =
            File(path.join(target.path, path.basename(entity.path)));
        await entity.copy(newFile.path);
      } else if (entity is Directory) {
        final newDir =
            Directory(path.join(target.path, path.basename(entity.path)));
        await _copyDirectory(entity, newDir);
      }
    }
  }

  Future<Map<String, dynamic>> renameFile(
      String filePath, String newName) async {
    try {
      final fullPath = path.join(_storagePath, filePath);
      final parentPath = path.dirname(fullPath);
      final newFullPath = path.join(parentPath, newName);

      final file = File(fullPath);
      final directory = Directory(fullPath);

      if (file.existsSync()) {
        await file.rename(newFullPath);
        print('✅ File renamed: $filePath -> $newName');
      } else if (directory.existsSync()) {
        await directory.rename(newFullPath);
        print('✅ Directory renamed: $filePath -> $newName');
      } else {
        return {
          'success': false,
          'error': 'File or directory not found: $filePath'
        };
      }

      return {
        'success': true,
        'message': 'File renamed successfully',
        'oldName': path.basename(filePath),
        'newName': newName
      };
    } catch (e) {
      print('❌ Error renaming file: $e');
      return {'success': false, 'error': 'Failed to rename file: $e'};
    }
  }
}
