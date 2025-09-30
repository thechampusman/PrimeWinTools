import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'file_manager.dart';
import 'media_streamer.dart';

class UDriveServer {
  static const String version = '1.0.0';

  final int port;
  HttpServer? _server;
  bool isRunning = false;
  String serverUrl = '';
  String storagePath = '';
  DateTime? startTime;
  int totalConnections = 0;
  int activeConnections = 0;

  late UDriveFileManager fileManager;
  late UDriveMediaStreamer mediaStreamer;

  Future<void> _handleStreamPath(HttpRequest request) async {
    try {
      // Extract file path from /stream/filename URL
      final filePath = Uri.decodeComponent(
          request.uri.path.substring(8)); // Remove '/stream/'
      print('🎬 Streaming file: $filePath');

      await mediaStreamer.streamFile(request, filePath);
    } catch (e) {
      print('❌ Failed to stream media: $e');
      request.response.statusCode = 500;
      request.response.write('Failed to stream media: $e');
      await request.response.close();
    }
  }

  Future<void> _handleDownloadPath(HttpRequest request) async {
    try {
      // Extract file path from /download/filename URL
      final filePath = Uri.decodeComponent(
          request.uri.path.substring(10)); // Remove '/download/'
      print('📥 Downloading file: $filePath');

      await fileManager.downloadFile(filePath, request.response);
    } catch (e) {
      print('❌ Failed to download file: $e');
      request.response.statusCode = 500;
      request.response.write('Failed to download file: $e');
      await request.response.close();
    }
  }

  late UDriveFileManager fileManager;
  late UDriveMediaStreamer mediaStreamer;

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
      print('💻 Local access only (no network sharing)');

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
    totalConnections++;
    activeConnections++;

    try {
      // Add CORS headers
      request.response.headers.add('Access-Control-Allow-Origin', '*');
      request.response.headers.add(
          'Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
      request.response.headers
          .add('Access-Control-Allow-Headers', 'Content-Type');

      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      final uri = request.uri;

      // Reduce logging noise for frequent /api/info requests
      if (uri.path != '/api/info') {
        print('📥 ${request.method} ${uri.path}');
      }

      // Route handling
      switch (uri.path) {
        case '/':
          await _serveStaticFile(request, 'index.html');
          break;
        case '/api/info':
          await _handleServerInfo(request);
          break;
        case '/api/files':
          await _handleFiles(request);
          break;
        case '/api/upload':
          await _handleUpload(request);
          break;
        case '/api/download':
          await _handleDownload(request);
          break;
        case '/api/delete':
          await _handleDelete(request);
          break;
        case '/api/search':
          await _handleSearch(request);
          break;
        case '/api/stream':
          await _handleStream(request);
          break;
        default:
          if (uri.path.startsWith('/stream/')) {
            await _handleStreamPath(request);
          } else if (uri.path.startsWith('/download/')) {
            await _handleDownloadPath(request);
          } else if (uri.path.startsWith('/css/') ||
              uri.path.startsWith('/js/') ||
              uri.path.startsWith('/assets/')) {
            await _serveStaticFile(request, uri.path.substring(1));
          } else {
            request.response.statusCode = 404;
            request.response.write('File not found');
            await request.response.close();
          }
          break;
      }
    } catch (e) {
      print('❌ Error handling request: $e');
      if (!request.response.isCompleted) {
        request.response.statusCode = 500;
        request.response.write('Internal Server Error');
        await request.response.close();
      }
    } finally {
      activeConnections--;
    }
  }

  Future<void> _serveStaticFile(HttpRequest request, String fileName) async {
    try {
      final webAssetsPath =
          path.join(Directory.current.path, 'lib', 'udrive', 'web_assets');
      final filePath = path.join(webAssetsPath, fileName);
      final file = File(filePath);

      if (!await file.exists()) {
        request.response.statusCode = 404;
        request.response.write('File not found: $fileName');
        await request.response.close();
        return;
      }

      // Set content type
      final extension = path.extension(fileName).toLowerCase();
      switch (extension) {
        case '.html':
          request.response.headers.contentType = ContentType.html;
          break;
        case '.css':
          request.response.headers.contentType = ContentType('text', 'css');
          break;
        case '.js':
          request.response.headers.contentType =
              ContentType('application', 'javascript');
          break;
        case '.json':
          request.response.headers.contentType = ContentType.json;
          break;
        case '.ico':
          request.response.headers.contentType = ContentType('image', 'x-icon');
          break;
        default:
          request.response.headers.contentType = ContentType.binary;
      }

      await file.openRead().pipe(request.response);
    } catch (e) {
      print('❌ Error serving static file: $e');
      request.response.statusCode = 500;
      request.response.write('Internal Server Error');
      await request.response.close();
    }
  }

  Future<void> _handleServerInfo(HttpRequest request) async {
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
      'network': {
        'primaryUrl': 'http://localhost:$port',
        'interfaces': [
          {
            'interface': 'localhost',
            'ip': '127.0.0.1',
            'url': 'http://localhost:$port',
            'isPrivate': true,
            'isPrimary': true,
          }
        ],
        'autoDetected': true,
      },
    });
  }

  Future<void> _handleFiles(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final relativePath = queryParams['path'] ?? '';
      final type = queryParams['type'];

      final result = await fileManager.getFiles(relativePath, type);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to get files: $e');
    }
  }

  Future<void> _handleUpload(HttpRequest request) async {
    try {
      final contentType = request.headers.contentType;
      if (contentType?.mimeType != 'multipart/form-data') {
        _sendJsonError(
            request.response, 'Content-Type must be multipart/form-data');
        return;
      }

      final transformer =
          MimeMultipartTransformer(contentType!.parameters['boundary']!);
      final parts = await transformer.bind(request).toList();

      String? uploadPath;
      String? fileName;
      List<int>? fileData;

      for (final part in parts) {
        final disposition = part.headers['content-disposition'];
        if (disposition != null) {
          if (disposition.contains('name="path"')) {
            uploadPath = await part.transform(utf8.decoder).join();
          } else if (disposition.contains('name="file"')) {
            final match = RegExp(r'filename="([^"]*)"').firstMatch(disposition);
            fileName = match?.group(1);
            fileData = await part
                .toList()
                .then((chunks) => chunks.expand((chunk) => chunk).toList());
          }
        }
      }

      if (fileName == null || fileData == null) {
        _sendJsonError(request.response, 'No file provided');
        return;
      }

      final result =
          await fileManager.uploadFile(fileName, fileData, uploadPath ?? '');
      _sendJsonResponse(request.response, result);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to upload file: $e');
    }
  }

  Future<void> _handleDownload(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final filePath = queryParams['path'];

      if (filePath == null || filePath.isEmpty) {
        _sendJsonError(request.response, 'File path is required');
        return;
      }

      await fileManager.downloadFile(filePath, request.response);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to download file: $e');
    }
  }

  Future<void> _handleDelete(HttpRequest request) async {
    try {
      final body = await utf8.decoder.bind(request).join();
      final data = jsonDecode(body);
      final filePath = data['path'];

      if (filePath == null || filePath.isEmpty) {
        _sendJsonError(request.response, 'File path is required');
        return;
      }

      final result = await fileManager.deleteFile(filePath);
      _sendJsonResponse(request.response, result);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to delete file: $e');
    }
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
      _sendJsonResponse(request.response, results);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to search files: $e');
    }
  }

  Future<void> _handleStream(HttpRequest request) async {
    try {
      final queryParams = request.uri.queryParameters;
      final filePath = queryParams['path'];

      if (filePath == null || filePath.isEmpty) {
        _sendJsonError(request.response, 'File path is required');
        return;
      }

      await mediaStreamer.streamFile(request, filePath);
    } catch (e) {
      _sendJsonError(request.response, 'Failed to stream media: $e');
    }
  }

  void _sendJsonResponse(HttpResponse response, Map<String, dynamic> data) {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
    response.close();
  }

  void _sendJsonError(HttpResponse response, String message) {
    response.statusCode = 400;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode({'success': false, 'error': message}));
    response.close();
  }
}
