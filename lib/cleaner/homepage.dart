import 'package:flutter/material.dart';
import 'dart:io';

class Cleaner extends StatefulWidget {
  const Cleaner({super.key});

  @override
  State<Cleaner> createState() => _CleanerState();
}

class _CleanerState extends State<Cleaner> {
  bool _isScanning = false;
  List<FileSystemEntity> _tempFiles = [];
  Map<String, List<FileSystemEntity>> _filesByFolder = {};
  String _selectedFolder = '';
  int _totalSize = 0;

  Map<String, bool> _cleaningCategories = {
    'temp_files': true,
    'thumbnail_cache': true,
    'recent_documents': false,
    'browser_cache': false,
    'download_history': false,
  };

  Map<String, bool> _expandedCategories = {};

  Map<String, List<FileSystemEntity>> _categoryFiles = {};
  Map<String, int> _categorySizes = {};
  Map<String, int> _categoryFileCounts = {};

  List<String> _scannedFolders = [
    'C:\\Windows\\Temp',
    'C:\\Users\\%USERNAME%\\AppData\\Local\\Temp',
    'C:\\Windows\\Prefetch',
  ];

  Widget _buildScannedFoldersStrip() {
    if (_scannedFolders.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.folder, color: Color(0xFF4CAF50), size: 18),
          const SizedBox(width: 8),
          const Text(
            'Default scan locations:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B5E20),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final p in _scannedFolders)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_right,
                              size: 16, color: Color(0xFF4CAF50)),
                          const SizedBox(width: 4),
                          Text(
                            p,
                            style: const TextStyle(
                                fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recently scanned folders quick view
            _buildScannedFoldersStrip(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),

                  // Subtle inner shadow
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.cleaning_services,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Cleaner',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Clean temporary files and optimize your system',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: _showCleaningSettingsDialog,
                          icon: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 20,
                          ),
                          tooltip: 'Cleaning Settings',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.folder_open,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Files Found',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_tempFiles.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.storage,
                                color: Colors.white.withOpacity(0.8),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Total Size',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatFileSize(_totalSize),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: _CleanButton(
                              text: _isScanning ? 'Scanning...' : 'Start Scan',
                              icon: Icons.search,
                              isPrimary: true,
                              onPressed: _isScanning ? null : _startScan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: _CleanButton(
                              text: 'Clean Now',
                              icon: Icons.cleaning_services,
                              isDestructive: true,
                              onPressed: (_tempFiles.isNotEmpty && !_isScanning)
                                  ? _cleanFiles
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: _CleanButton(
                              text: 'Quick Clean',
                              icon: Icons.flash_on,
                              onPressed: !_isScanning ? _quickClean : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isScanning && _selectedFolder.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFF3B82F6),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Currently scanning',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _selectedFolder,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const LinearProgressIndicator(
                          backgroundColor: Color(0xFFE5E7EB),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.transparent),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_categoryFiles.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.folder_open,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Files and Folders Found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._buildCategoryResults(),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _tempFiles.clear();
      _filesByFolder.clear();
      _totalSize = 0;
      _categoryFiles.clear();
      _categorySizes.clear();
      _categoryFileCounts.clear();
    });

    for (String category in _cleaningCategories.keys) {
      if (_cleaningCategories[category] == true) {
        await _scanCategory(category);
      }
    }

    setState(() {
      _isScanning = false;
      _selectedFolder = '';
    });
  }

  Future<void> _scanCategory(String category) async {
    List<FileSystemEntity> categoryFileList = [];
    int categorySize = 0;

    setState(() {
      _selectedFolder = 'Scanning ${_getCategoryName(category)}...';
    });

    try {
      switch (category) {
        case 'temp_files':
          await _scanTempFiles(categoryFileList);
          break;
        case 'thumbnail_cache':
          await _scanThumbnailCache(categoryFileList);
          break;
        case 'recent_documents':
          await _scanRecentDocuments(categoryFileList);
          break;
        case 'browser_cache':
          await _scanBrowserCache(categoryFileList);
          break;
        case 'download_history':
          await _scanDownloadHistory(categoryFileList);
          break;
      }

      for (FileSystemEntity file in categoryFileList) {
        if (file is File) {
          try {
            int fileSize = await file.length();
            categorySize += fileSize;
          } catch (e) {}
        }
      }

      setState(() {
        _categoryFiles[category] = categoryFileList;
        _categorySizes[category] = categorySize;
        _categoryFileCounts[category] = categoryFileList.length;
        _totalSize += categorySize;
        _tempFiles.addAll(categoryFileList);
      });
    } catch (e) {
      print('Error scanning category $category: $e');
    }
  }

  void _cleanFiles() async {
    if (_tempFiles.isEmpty) return;

    int deletedCount = 0;
    int deletedSize = 0;

    for (int i = _tempFiles.length - 1; i >= 0; i--) {
      try {
        File file = _tempFiles[i] as File;
        int fileSize = await file.length();
        await file.delete();

        setState(() {
          _tempFiles.removeAt(i);
          _totalSize -= fileSize;
        });

        deletedCount++;
        deletedSize += fileSize;
      } catch (e) {
        print('Error deleting file: $e');
        setState(() {
          _tempFiles.removeAt(i);
        });
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Cleaned $deletedCount files (${_formatFileSize(deletedSize)})'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _quickClean() async {
    _startScan();
    await Future.delayed(const Duration(seconds: 1));
    if (_tempFiles.isNotEmpty) {
      _cleanFiles();
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  List<Widget> _buildCategoryResults() {
    List<Widget> categoryWidgets = [];

    for (String category in _categoryFiles.keys) {
      List<FileSystemEntity> files = _categoryFiles[category] ?? [];
      if (files.isEmpty) continue;

      String categoryName = _getCategoryName(category);
      int fileCount = _categoryFileCounts[category] ?? 0;
      int categorySize = _categorySizes[category] ?? 0;

      categoryWidgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB).withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(category),
                    size: 20,
                    color: const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$fileCount files • ${_formatFileSize(categorySize)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: (_expandedCategories[category] == true)
                    ? (files.length * 50.0).clamp(120, 300)
                    : 120,
                child: ListView.separated(
                  itemCount: (_expandedCategories[category] == true)
                      ? files.length
                      : files.length.clamp(0, 5),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    FileSystemEntity entity = files[index];
                    String fileName = entity.path.split('\\').last;
                    String folderPath = entity.parent.path;
                    bool isDirectory = entity is Directory;

                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isDirectory
                                ? Icons.folder
                                : Icons.insert_drive_file,
                            size: 16,
                            color: isDirectory
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  folderPath,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (files.length > 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _expandedCategories[category] =
                            !(_expandedCategories[category] ?? false);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            (_expandedCategories[category] == true)
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 16,
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (_expandedCategories[category] == true)
                                ? 'Show Less'
                                : 'Show All (${files.length} files)',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return categoryWidgets;
  }

  IconData _getCategoryIcon(String category) {
    Map<String, IconData> icons = {
      'temp_files': Icons.delete,
      'thumbnail_cache': Icons.image,
      'recent_documents': Icons.history,
      'browser_cache': Icons.web,
      'download_history': Icons.download,
    };
    return icons[category] ?? Icons.folder;
  }

  String _getCategoryName(String category) {
    Map<String, String> names = {
      'temp_files': 'Temporary Files',
      'thumbnail_cache': 'Thumbnail Cache',
      'recent_documents': 'Recent Documents',
      'browser_cache': 'Browser Cache',
      'download_history': 'Download History',
    };
    return names[category] ?? category;
  }

  Future<void> _scanTempFiles(List<FileSystemEntity> categoryFileList) async {
    List<String> tempFolders = [
      'C:\\Windows\\Temp',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Temp',
      'C:\\Windows\\Prefetch',
    ];

    for (String folder in tempFolders) {
      try {
        Directory directory = Directory(folder);
        if (await directory.exists()) {
          await for (FileSystemEntity entity in directory.list()) {
            if (entity is File) {
              categoryFileList.add(entity);
            }
          }
        }
      } catch (e) {
        print('Error scanning temp folder $folder: $e');
      }
    }
  }

  Future<void> _scanThumbnailCache(
      List<FileSystemEntity> categoryFileList) async {
    List<String> thumbnailPaths = [
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Microsoft\\Windows\\Explorer',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\IconCache.db',
    ];

    for (String path in thumbnailPaths) {
      try {
        if (path.endsWith('.db')) {
          File file = File(path);
          if (await file.exists()) {
            categoryFileList.add(file);
          }
        } else {
          Directory directory = Directory(path);
          if (await directory.exists()) {
            await for (FileSystemEntity entity
                in directory.list(recursive: true)) {
              if (entity is File &&
                  (entity.path.contains('thumbcache') ||
                      entity.path.contains('iconcache') ||
                      entity.path.contains('.db'))) {
                categoryFileList.add(entity);
              }
            }
          }
        }
      } catch (e) {
        print('Error scanning thumbnail path $path: $e');
      }
    }
  }

  Future<void> _scanRecentDocuments(
      List<FileSystemEntity> categoryFileList) async {
    List<String> recentPaths = [
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\Recent',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Roaming\\Microsoft\\Windows\\Recent',
    ];

    for (String path in recentPaths) {
      try {
        Directory directory = Directory(path);
        if (await directory.exists()) {
          await for (FileSystemEntity entity in directory.list()) {
            if (entity is File) {
              categoryFileList.add(entity);
            }
          }
        }
      } catch (e) {
        print('Error scanning recent documents $path: $e');
      }
    }
  }

  Future<void> _scanBrowserCache(
      List<FileSystemEntity> categoryFileList) async {
    List<String> browserCachePaths = [
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\Cache',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\Cache',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles',
    ];

    for (String path in browserCachePaths) {
      try {
        Directory directory = Directory(path);
        if (await directory.exists()) {
          if (path.contains('Firefox')) {
            await for (FileSystemEntity profileEntity in directory.list()) {
              if (profileEntity is Directory) {
                Directory cacheDir = Directory('${profileEntity.path}\\cache2');
                if (await cacheDir.exists()) {
                  await for (FileSystemEntity entity
                      in cacheDir.list(recursive: true)) {
                    if (entity is File) {
                      categoryFileList.add(entity);
                    }
                  }
                }
              }
            }
          } else {
            await for (FileSystemEntity entity in directory.list()) {
              if (entity is File) {
                categoryFileList.add(entity);
              }
            }
          }
        }
      } catch (e) {
        print('Error scanning browser cache $path: $e');
      }
    }
  }

  Future<void> _scanDownloadHistory(
      List<FileSystemEntity> categoryFileList) async {
    List<String> downloadHistoryPaths = [
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\History',
      'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\History',
    ];

    for (String path in downloadHistoryPaths) {
      try {
        File file = File(path);
        if (await file.exists()) {
          categoryFileList.add(file);
        }
      } catch (e) {
        print('Error scanning download history $path: $e');
      }
    }
  }

  void _showCleaningSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Row(
                        children: const [
                          Icon(Icons.settings,
                              color: Color(0xFF667EEA), size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Cleaning Settings',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select what you want to clean:',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                      ),
                      const SizedBox(height: 20),
                      // Preset chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildPresetChip('Safe', Icons.shield_moon,
                              const Color(0xFF10B981), () {
                            _applyPreset('safe');
                            setStateDialog(() {});
                          }),
                          _buildPresetChip('Balanced', Icons.auto_awesome,
                              const Color(0xFF6366F1), () {
                            _applyPreset('balanced');
                            setStateDialog(() {});
                          }),
                          _buildPresetChip('Aggressive', Icons.speed,
                              const Color(0xFFEF4444), () {
                            _applyPreset('aggressive');
                            setStateDialog(() {});
                          }),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Scrollable content
                      Flexible(
                        child: SingleChildScrollView(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final maxW = constraints.maxWidth;
                              // target card width ~ 300
                              final cardW =
                                  maxW >= 620 ? (maxW - 16) / 2 : maxW;
                              return Wrap(
                                spacing: 16,
                                runSpacing: 12,
                                children: [
                                  _buildCategoryCard(
                                      width: cardW,
                                      keyName: 'temp_files',
                                      title: 'Temporary Files',
                                      description:
                                          'System temporary files and cache',
                                      icon: Icons.delete,
                                      color: const Color(0xFF0EA5E9),
                                      setStateDialog: setStateDialog),
                                  _buildCategoryCard(
                                      width: cardW,
                                      keyName: 'thumbnail_cache',
                                      title: 'Privacy - Thumbnail Cache',
                                      description:
                                          'Removes traces of viewed images/videos',
                                      icon: Icons.image,
                                      color: const Color(0xFF8B5CF6),
                                      setStateDialog: setStateDialog),
                                  _buildCategoryCard(
                                      width: cardW,
                                      keyName: 'recent_documents',
                                      title: 'Recent Documents',
                                      description:
                                          'Recently accessed file history',
                                      icon: Icons.history,
                                      color: const Color(0xFF10B981),
                                      setStateDialog: setStateDialog),
                                  _buildCategoryCard(
                                      width: cardW,
                                      keyName: 'browser_cache',
                                      title: 'Browser Cache',
                                      description: 'Web browser cached files',
                                      icon: Icons.web,
                                      color: const Color(0xFFF59E0B),
                                      setStateDialog: setStateDialog),
                                  _buildCategoryCard(
                                      width: cardW,
                                      keyName: 'download_history',
                                      title: 'Download History',
                                      description: 'Downloaded file history',
                                      icon: Icons.download,
                                      color: const Color(0xFFEF4444),
                                      setStateDialog: setStateDialog),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _cleaningCategories
                                    .updateAll((key, value) => false);
                              });
                              setStateDialog(() {});
                            },
                            child: const Text('Clear All'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _cleaningCategories
                                    .updateAll((key, value) => true);
                              });
                              setStateDialog(() {});
                            },
                            child: const Text('Select All'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetChip(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color.darken(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyPreset(String preset) {
    Map<String, bool> config;
    switch (preset) {
      case 'safe':
        config = {
          'temp_files': true,
          'thumbnail_cache': true,
          'recent_documents': false,
          'browser_cache': false,
          'download_history': false,
        };
        break;
      case 'balanced':
        config = {
          'temp_files': true,
          'thumbnail_cache': true,
          'recent_documents': true,
          'browser_cache': false,
          'download_history': false,
        };
        break;
      case 'aggressive':
      default:
        config = {
          'temp_files': true,
          'thumbnail_cache': true,
          'recent_documents': true,
          'browser_cache': true,
          'download_history': true,
        };
    }
    _cleaningCategories = Map<String, bool>.from(config);
  }

  Widget _buildCategoryCard({
    required double width,
    required String keyName,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required StateSetter setStateDialog,
  }) {
    final isSelected = _cleaningCategories[keyName] ?? false;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _toggleCategory(keyName);
            setStateDialog(() {});
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.06) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color.withOpacity(0.45) : Colors.grey[300]!,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.35)),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? color.darken()
                                    : const Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Switch.adaptive(
                            value: isSelected,
                            onChanged: (val) {
                              _cleaningCategories[keyName] = val;
                              setStateDialog(() {});
                            },
                            activeColor: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleCategory(String keyName) {
    final current = _cleaningCategories[keyName] ?? false;
    _cleaningCategories[keyName] = !current;
  }
}

class _CleanButton extends StatefulWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;

  const _CleanButton({
    required this.text,
    required this.icon,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });

  @override
  State<_CleanButton> createState() => _CleanButtonState();
}

class _CleanButtonState extends State<_CleanButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    bool isDisabled = widget.onPressed == null;

    Color getTextColor() {
      if (isDisabled) {
        return const Color(0xFF9CA3AF);
      }
      return Colors.white;
    }

    void scheduleHover(bool value) {
      if (!mounted) return;
      if (_isHovered == value) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _isHovered = value);
      });
    }

    return MouseRegion(
      onEnter: isDisabled ? null : (_) => scheduleHover(true),
      onExit: isDisabled ? null : (_) => scheduleHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : LinearGradient(
                  colors: widget.isPrimary
                      ? [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)]
                      : widget.isDestructive
                          ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                          : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: isDisabled ? const Color(0xFFF3F4F6) : null,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isDisabled || !_isHovered
              ? []
              : [
                  BoxShadow(
                    color: widget.isPrimary
                        ? const Color(0xFF3B82F6).withOpacity(0.3)
                        : widget.isDestructive
                            ? const Color(0xFFEF4444).withOpacity(0.3)
                            : const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: getTextColor(),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: getTextColor(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _ColorX on Color {
  Color darken([double amount = 0.15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }
}
