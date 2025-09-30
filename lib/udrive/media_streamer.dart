import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class UDriveMediaStreamer {
  static const int defaultChunkSize = 8192; // 8KB chunks
  static const Map<String, String> mimeTypes = {
    // Video formats - Complete list
    'mp4': 'video/mp4',
    'webm': 'video/webm',
    'ogv': 'video/ogg',
    'avi': 'video/x-msvideo',
    'mov': 'video/quicktime',
    'wmv': 'video/x-ms-wmv',
    'flv': 'video/x-flv',
    'mkv': 'video/x-matroska',
    'mka': 'video/x-matroska',
    'm4v': 'video/x-m4v',
    '3gp': 'video/3gpp',
    '3g2': 'video/3gpp2',
    'ts': 'video/mp2t',
    'mts': 'video/mp2t',
    'm2ts': 'video/mp2t',
    'asf': 'video/x-ms-asf',
    'rm': 'application/vnd.rn-realmedia',
    'rmvb': 'application/vnd.rn-realmedia-vbr',
    'divx': 'video/divx',
    'xvid': 'video/x-msvideo',
    'vob': 'video/x-ms-vob',
    'f4v': 'video/x-f4v',
    'm2v': 'video/mpeg',
    'mpg': 'video/mpeg',
    'mpeg': 'video/mpeg',
    'mpe': 'video/mpeg',
    'mpv': 'video/mpeg',
    'qt': 'video/quicktime',
    'swf': 'application/x-shockwave-flash',
    'yuv': 'video/x-yuv',
    'webmv': 'video/webm',
    'dv': 'video/x-dv',
    'dat': 'video/mpeg',
    'nsv': 'video/x-nsv',

    // Audio formats - Complete list
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'aac': 'audio/aac',
    'm4a': 'audio/mp4',
    'flac': 'audio/flac',
    'wma': 'audio/x-ms-wma',
    'ogg': 'audio/ogg',
    'oga': 'audio/ogg',
    'opus': 'audio/opus',
    'ac3': 'audio/ac3',
    'au': 'audio/basic',
    'aiff': 'audio/aiff',
    'aif': 'audio/aiff',
    'aifc': 'audio/aiff',
    'amr': 'audio/amr',
    'awb': 'audio/amr-wb',
    'dts': 'audio/vnd.dts',
    'dtshd': 'audio/vnd.dts.hd',
    'ra': 'audio/x-realaudio',
    'ram': 'audio/x-pn-realaudio',
    'ape': 'audio/x-ape',
    'caf': 'audio/x-caf',
    'mid': 'audio/midi',
    'midi': 'audio/midi',
    'kar': 'audio/midi',
    'gsm': 'audio/gsm',
    '3ga': 'audio/3gpp',
    'mp2': 'audio/mpeg',
    'mpa': 'audio/mpeg',

    // Image formats - Complete list
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'jpe': 'image/jpeg',
    'jfif': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
    'svgz': 'image/svg+xml',
    'bmp': 'image/bmp',
    'dib': 'image/bmp',
    'ico': 'image/x-icon',
    'cur': 'image/x-icon',
    'tiff': 'image/tiff',
    'tif': 'image/tiff',
    'psd': 'image/vnd.adobe.photoshop',
    'ai': 'application/postscript',
    'eps': 'application/postscript',
    'ps': 'application/postscript',
    'pcx': 'image/x-pcx',
    'tga': 'image/x-tga',
    'jp2': 'image/jp2',
    'jpx': 'image/jpx',
    'jpm': 'image/jpm',
    'mj2': 'image/mj2',
    'xbm': 'image/x-xbitmap',
    'xpm': 'image/x-xpixmap',
    'pbm': 'image/x-portable-bitmap',
    'pgm': 'image/x-portable-graymap',
    'ppm': 'image/x-portable-pixmap',
    'pnm': 'image/x-portable-anymap',
    'ras': 'image/x-cmu-raster',
    'sgi': 'image/sgi',
    'jng': 'image/x-jng',
    'wbmp': 'image/vnd.wap.wbmp',
    'cr2': 'image/x-canon-cr2',
    'crw': 'image/x-canon-crw',
    'nef': 'image/x-nikon-nef',
    'orf': 'image/x-olympus-orf',
    'raf': 'image/x-fuji-raf',
    'rw2': 'image/x-panasonic-rw2',
    'srw': 'image/x-samsung-srw',
    'arw': 'image/x-sony-arw',
    'dng': 'image/x-adobe-dng',
    'pef': 'image/x-pentax-pef',
    'x3f': 'image/x-sigma-x3f',
    'raw': 'image/x-panasonic-raw',
    'dcr': 'image/x-kodak-dcr',
    'kdc': 'image/x-kodak-kdc',
    'erf': 'image/x-epson-erf',
    'mef': 'image/x-mamiya-mef',
    'mrw': 'image/x-minolta-mrw',
    '3fr': 'image/x-hasselblad-3fr',
    'fff': 'image/x-hasselblad-fff',
    'iiq': 'image/x-phaseone-iiq',
    'k25': 'image/x-kodak-k25',
    'rwl': 'image/x-leica-rwl',
    'dcs': 'image/x-kodak-dcs',
    'avif': 'image/avif',
    'heic': 'image/heic',
    'heif': 'image/heif',

    // Document formats (for preview support)
    'pdf': 'application/pdf',
    'txt': 'text/plain',
    'rtf': 'application/rtf',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',

    // Archive formats
    'zip': 'application/zip',
    'rar': 'application/x-rar-compressed',
    '7z': 'application/x-7z-compressed',
    'tar': 'application/x-tar',
    'gz': 'application/gzip',
    'bz2': 'application/x-bzip2',
    'xz': 'application/x-xz',

    // Other common formats
    'json': 'application/json',
    'xml': 'application/xml',
    'css': 'text/css',
    'js': 'application/javascript',
    'html': 'text/html',
    'htm': 'text/html',
    'md': 'text/markdown',
    'log': 'text/plain',
    'ini': 'text/plain',
    'cfg': 'text/plain',
    'conf': 'text/plain',
  };

  String storagePath = '';

  void setStoragePath(String path) {
    storagePath = path;
  }

  // Stream media file with range support for seeking
  Future<void> streamFile(HttpRequest request, String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('File not found');
        await request.response.close();
        return;
      }

      final stat = await file.stat();
      final fileSize = stat.size;
      final fileName = path.basename(file.path);
      final fileExt =
          path.extension(fileName).toLowerCase().replaceFirst('.', '');

      // Get MIME type
      final mimeType = mimeTypes[fileExt] ?? 'application/octet-stream';

      // Parse Range header for partial content requests
      String? rangeHeader = request.headers.value('range');
      int start = 0;
      int end = fileSize - 1;

      if (rangeHeader != null) {
        final rangeMatch = RegExp(r'bytes=(\d*)-(\d*)').firstMatch(rangeHeader);
        if (rangeMatch != null) {
          final startStr = rangeMatch.group(1);
          final endStr = rangeMatch.group(2);

          if (startStr != null && startStr.isNotEmpty) {
            start = int.parse(startStr);
          }
          if (endStr != null && endStr.isNotEmpty) {
            end = int.parse(endStr);
          }

          // Ensure end doesn't exceed file size
          if (end >= fileSize) {
            end = fileSize - 1;
          }
        }
      }

      final contentLength = end - start + 1;

      // Set response headers
      request.response.headers.set('Content-Type', mimeType);
      request.response.headers.set('Accept-Ranges', 'bytes');
      request.response.headers.set('Content-Length', contentLength.toString());

      // Add CORS headers for cross-origin requests
      request.response.headers.set('Access-Control-Allow-Origin', '*');
      request.response.headers
          .set('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
      request.response.headers
          .set('Access-Control-Allow-Headers', 'Range, Content-Type');
      request.response.headers.set('Access-Control-Expose-Headers',
          'Content-Range, Content-Length, Accept-Ranges');

      if (rangeHeader != null) {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers
            .set('Content-Range', 'bytes $start-$end/$fileSize');
      } else {
        request.response.statusCode = HttpStatus.ok;
      }

      // Enable caching for media files
      request.response.headers.set('Cache-Control', 'public, max-age=3600');
      request.response.headers
          .set('Last-Modified', HttpDate.format(stat.modified));

      // Add additional video-specific headers
      if (mimeType.startsWith('video/')) {
        request.response.headers.set('X-Content-Type-Options', 'nosniff');
      }

      print(
          '📺 Streaming $mimeType file: $fileName (bytes $start-$end/$fileSize)');

      // Stream the file content
      await _streamFileChunk(file, request.response, start, end);
    } catch (e) {
      print('Streaming error: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Streaming failed');
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _streamFileChunk(
      File file, HttpResponse response, int start, int end) async {
    try {
      final randomAccessFile = await file.open();
      await randomAccessFile.setPosition(start);

      int bytesLeft = end - start + 1;
      final buffer = List<int>.filled(defaultChunkSize, 0);

      while (bytesLeft > 0) {
        final chunkSize =
            bytesLeft > defaultChunkSize ? defaultChunkSize : bytesLeft;
        final bytesRead = await randomAccessFile.readInto(buffer, 0, chunkSize);

        if (bytesRead == 0) break;

        // Write chunk to response
        response.add(buffer.sublist(0, bytesRead));
        bytesLeft -= bytesRead;

        // Yield control to allow other operations
        await Future.delayed(Duration.zero);
      }

      await randomAccessFile.close();
      await response.close();
    } catch (e) {
      print('Chunk streaming error: $e');
      try {
        await response.close();
      } catch (_) {}
    }
  }

  // Get media file information
  Future<Map<String, dynamic>?> getMediaInfo(String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        return null;
      }

      final stat = await file.stat();
      final fileName = path.basename(file.path);
      final fileExt =
          path.extension(fileName).toLowerCase().replaceFirst('.', '');
      final mimeType = mimeTypes[fileExt] ?? 'application/octet-stream';

      final mediaInfo = {
        'name': fileName,
        'path': relativePath,
        'size': stat.size,
        'mimeType': mimeType,
        'type': _getMediaType(fileExt),
        'extension': fileExt,
        'modified': stat.modified.toIso8601String(),
        'duration': null, // Could be extended with ffprobe integration
        'thumbnail': null, // Could be extended with thumbnail generation
      };

      return mediaInfo;
    } catch (e) {
      print('Error getting media info: $e');
      return null;
    }
  }

  // Get thumbnail for video files (placeholder implementation)
  Future<void> serveThumbnail(HttpRequest request, String relativePath) async {
    try {
      final fullPath = path.join(storagePath, relativePath);
      final file = File(fullPath);

      if (!file.existsSync()) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('File not found');
        await request.response.close();
        return;
      }

      final fileExt =
          path.extension(file.path).toLowerCase().replaceFirst('.', '');

      // For now, return a default thumbnail
      // In a real implementation, you would use ffmpeg to generate thumbnails
      await _serveDefaultThumbnail(request, _getMediaType(fileExt));
    } catch (e) {
      print('Thumbnail error: $e');
      await _serveDefaultThumbnail(request, 'unknown');
    }
  }

  Future<void> _serveDefaultThumbnail(
      HttpRequest request, String mediaType) async {
    try {
      // Generate a simple SVG placeholder
      final svgContent = _generateThumbnailSvg(mediaType);

      request.response.headers.set('Content-Type', 'image/svg+xml');
      request.response.headers.set('Cache-Control', 'public, max-age=86400');
      request.response.write(svgContent);
      await request.response.close();
    } catch (e) {
      print('Default thumbnail error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  String _generateThumbnailSvg(String mediaType) {
    final color = mediaType == 'video'
        ? '#FF6B6B'
        : mediaType == 'audio'
            ? '#4ECDC4'
            : '#95A5A6';
    final icon = mediaType == 'video'
        ? '▶'
        : mediaType == 'audio'
            ? '♪'
            : '?';

    return '''<?xml version="1.0" encoding="UTF-8"?>
<svg width="150" height="100" xmlns="http://www.w3.org/2000/svg">
  <rect width="150" height="100" fill="$color" rx="8"/>
  <text x="75" y="60" font-family="Arial, sans-serif" font-size="32" 
        fill="white" text-anchor="middle">$icon</text>
</svg>''';
  }

  // Get list of all media files
  Future<List<Map<String, dynamic>>> getMediaFiles([String? mediaType]) async {
    try {
      final mediaFiles = <Map<String, dynamic>>[];
      await _findMediaInDirectory(
          Directory(storagePath), mediaFiles, mediaType);

      // Sort by modified date (newest first)
      mediaFiles.sort((a, b) => DateTime.parse(b['modified'])
          .compareTo(DateTime.parse(a['modified'])));

      return mediaFiles;
    } catch (e) {
      print('Error getting media files: $e');
      return [];
    }
  }

  Future<void> _findMediaInDirectory(Directory directory,
      List<Map<String, dynamic>> mediaFiles, String? filterType) async {
    try {
      await for (final entity in directory.list()) {
        final fileName = path.basename(entity.path);

        // Skip hidden files
        if (fileName.startsWith('.')) continue;

        if (entity is Directory) {
          await _findMediaInDirectory(entity, mediaFiles, filterType);
        } else if (entity is File) {
          final fileExt =
              path.extension(fileName).toLowerCase().replaceFirst('.', '');
          final mediaType = _getMediaType(fileExt);

          if (mediaType != 'unknown' &&
              (filterType == null || mediaType == filterType)) {
            final stat = await entity.stat();

            mediaFiles.add({
              'name': fileName,
              'path': path.relative(entity.path, from: storagePath),
              'size': stat.size,
              'type': mediaType,
              'mimeType': mimeTypes[fileExt] ?? 'application/octet-stream',
              'extension': fileExt,
              'modified': stat.modified.toIso8601String(),
            });
          }
        }
      }
    } catch (e) {
      print('Error finding media in directory ${directory.path}: $e');
    }
  }

  String _getMediaType(String fileExt) {
    if (['mp4', 'webm', 'ogg', 'avi', 'mov', 'wmv', 'flv', 'mkv', 'm4v']
        .contains(fileExt)) {
      return 'video';
    } else if (['mp3', 'wav', 'ogg', 'aac', 'm4a', 'flac', 'wma']
        .contains(fileExt)) {
      return 'audio';
    } else if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg', 'bmp', 'ico']
        .contains(fileExt)) {
      return 'image';
    }
    return 'unknown';
  }

  // Create a playlist from media files
  Future<Map<String, dynamic>> createPlaylist(
      List<String> filePaths, String playlistName) async {
    try {
      final playlist = {
        'name': playlistName,
        'created': DateTime.now().toIso8601String(),
        'files': <Map<String, dynamic>>[],
      };

      for (final filePath in filePaths) {
        final mediaInfo = await getMediaInfo(filePath);
        if (mediaInfo != null) {
          (playlist['files'] as List<Map<String, dynamic>>).add(mediaInfo);
        }
      }

      // Save playlist to file
      final playlistPath =
          path.join(storagePath, 'playlists', '$playlistName.json');
      await Directory(path.dirname(playlistPath)).create(recursive: true);

      final playlistFile = File(playlistPath);
      await playlistFile.writeAsString(jsonEncode(playlist));

      return playlist;
    } catch (e) {
      print('Error creating playlist: $e');
      return {};
    }
  }

  // Get saved playlists
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    try {
      final playlistsDir = Directory(path.join(storagePath, 'playlists'));

      if (!playlistsDir.existsSync()) {
        return [];
      }

      final playlists = <Map<String, dynamic>>[];

      await for (final entity in playlistsDir.list()) {
        if (entity is File && path.extension(entity.path) == '.json') {
          try {
            final content = await entity.readAsString();
            final playlist = jsonDecode(content);
            playlists.add(playlist);
          } catch (e) {
            print('Error reading playlist ${entity.path}: $e');
          }
        }
      }

      // Sort by creation date (newest first)
      playlists.sort((a, b) =>
          DateTime.parse(b['created']).compareTo(DateTime.parse(a['created'])));

      return playlists;
    } catch (e) {
      print('Error getting playlists: $e');
      return [];
    }
  }

  // Stream subtitle files if available
  Future<void> serveSubtitles(HttpRequest request, String relativePath) async {
    try {
      // Remove video extension and look for subtitle files
      final basePath =
          path.withoutExtension(path.join(storagePath, relativePath));
      final subtitleExtensions = ['srt', 'vtt', 'ass', 'ssa'];

      for (final ext in subtitleExtensions) {
        final subtitlePath = '$basePath.$ext';
        final subtitleFile = File(subtitlePath);

        if (subtitleFile.existsSync()) {
          request.response.headers
              .set('Content-Type', 'text/vtt; charset=utf-8');
          request.response.headers.set('Cache-Control', 'public, max-age=3600');

          // Convert SRT to VTT if needed
          if (ext == 'srt') {
            final srtContent = await subtitleFile.readAsString();
            final vttContent = _convertSrtToVtt(srtContent);
            request.response.write(vttContent);
          } else {
            await subtitleFile.openRead().pipe(request.response);
          }
          return;
        }
      }

      // No subtitles found
      request.response.statusCode = HttpStatus.notFound;
      request.response.write('No subtitles found');
      await request.response.close();
    } catch (e) {
      print('Subtitle error: $e');
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  String _convertSrtToVtt(String srtContent) {
    // Simple SRT to VTT conversion
    String vttContent = 'WEBVTT\n\n';

    // Replace SRT time format with VTT format
    vttContent += srtContent.replaceAllMapped(
      RegExp(
          r'(\d{2}):(\d{2}):(\d{2}),(\d{3}) --> (\d{2}):(\d{2}):(\d{2}),(\d{3})'),
      (match) =>
          '${match.group(1)}:${match.group(2)}:${match.group(3)}.${match.group(4)} --> ${match.group(5)}:${match.group(6)}:${match.group(7)}.${match.group(8)}',
    );

    return vttContent;
  }
}
