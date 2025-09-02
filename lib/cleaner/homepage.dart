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
  bool _showAllFiles = false;
  List<String> _scannedFolders = [
    'C:\\Windows\\Temp',
    'C:\\Users\\%USERNAME%\\AppData\\Local\\Temp',
    'C:\\Windows\\Prefetch',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA), // Clean light background
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24), // Reduced from 40
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clean Header with gradient background
            Container(
              padding: const EdgeInsets.all(20), // Reduced from 32
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12), // Reduced from 16
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 15, // Reduced from 20
                    offset: const Offset(0, 6), // Reduced from 10
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8), // Reduced from 12
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(8), // Reduced from 12
                        ),
                        child: const Icon(
                          Icons.cleaning_services,
                          color: Colors.white,
                          size: 24, // Reduced from 32
                        ),
                      ),
                      const SizedBox(width: 12), // Reduced from 16
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System Cleaner',
                              style: TextStyle(
                                fontSize: 24, // Reduced from 32
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 2), // Reduced from 4
                            Text(
                              'Clean temporary files and optimize your system',
                              style: TextStyle(
                                fontSize: 14, // Reduced from 16
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20), // Reduced from 32

            // Action Buttons Container - Always visible with modern design
            Container(
              padding: const EdgeInsets.all(20), // Reduced from 32
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16), // Reduced from 20
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06), // Reduced opacity
                    blurRadius: 15, // Reduced from 20
                    offset: const Offset(0, 4), // Reduced from 8
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03), // Reduced opacity
                    blurRadius: 4, // Reduced from 6
                    offset: const Offset(0, 1), // Reduced from 2
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Files Found - Modern card design
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16), // Reduced from 20
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(12), // Reduced from 16
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.folder_open,
                                color: Colors.white.withOpacity(0.8),
                                size: 16, // Reduced from 20
                              ),
                              const SizedBox(width: 6), // Reduced from 8
                              const Text(
                                'Files Found',
                                style: TextStyle(
                                  fontSize: 12, // Reduced from 14
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6), // Reduced from 8
                          Text(
                            '${_tempFiles.length}',
                            style: const TextStyle(
                              fontSize: 22, // Reduced from 28
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Reduced from 20
                  // Total Size - Modern card design
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16), // Reduced from 20
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius:
                            BorderRadius.circular(12), // Reduced from 16
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.storage,
                                color: Colors.white.withOpacity(0.8),
                                size: 16, // Reduced from 20
                              ),
                              const SizedBox(width: 6), // Reduced from 8
                              const Text(
                                'Total Size',
                                style: TextStyle(
                                  fontSize: 12, // Reduced from 14
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6), // Reduced from 8
                          Text(
                            _formatFileSize(_totalSize),
                            style: const TextStyle(
                              fontSize: 22, // Reduced from 28
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Reduced from 20
                  // Action Buttons - Always show Start Scan, Clean Now, Quick Clean
                  Expanded(
                    flex: 6,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40, // Reduced from 48
                            child: _CleanButton(
                              text: _isScanning ? 'Scanning...' : 'Start Scan',
                              icon: Icons.search,
                              isPrimary: true,
                              onPressed: _isScanning ? null : _startScan,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6), // Reduced from 8
                        Expanded(
                          child: SizedBox(
                            height: 40, // Reduced from 48
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
                        const SizedBox(width: 6), // Reduced from 8
                        Expanded(
                          child: SizedBox(
                            height: 40, // Reduced from 48
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

            const SizedBox(height: 20), // Reduced from 32

            // Scanning Status with modern design
            if (_isScanning && _selectedFolder.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20), // Reduced from 28
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Reduced from 20
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      blurRadius: 15, // Reduced from 20
                      offset: const Offset(0, 4), // Reduced from 8
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6), // Reduced from 8
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(6), // Reduced from 8
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFF3B82F6),
                            size: 16, // Reduced from 20
                          ),
                        ),
                        const SizedBox(width: 10), // Reduced from 12
                        const Text(
                          'Currently scanning',
                          style: TextStyle(
                            fontSize: 14, // Reduced from 16
                            color: Color(0xFF1F2937),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12), // Reduced from 16
                    Container(
                      padding: const EdgeInsets.all(12), // Reduced from 16
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius:
                            BorderRadius.circular(8), // Reduced from 12
                      ),
                      child: Text(
                        _selectedFolder,
                        style: const TextStyle(
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16), // Reduced from 20
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6), // Reduced from 8
                      child: Container(
                        height: 6, // Reduced from 8
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: const LinearProgressIndicator(
                          backgroundColor: Color(0xFFE5E7EB),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.transparent),
                          minHeight: 6, // Reduced from 8
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20), // Reduced from 32
            ],

            // File List with modern design
            if (_tempFiles.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20), // Reduced from 28
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16), // Reduced from 20
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06), // Reduced opacity
                      blurRadius: 15, // Reduced from 20
                      offset: const Offset(0, 4), // Reduced from 8
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                                  const EdgeInsets.all(6), // Reduced from 8
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(6), // Reduced from 8
                              ),
                              child: const Icon(
                                Icons.folder_open,
                                color: Color(0xFF10B981),
                                size: 16, // Reduced from 20
                              ),
                            ),
                            const SizedBox(width: 10), // Reduced from 12
                            const Text(
                              'Files and Folders Found',
                              style: TextStyle(
                                fontSize: 16, // Reduced from 20
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius:
                                BorderRadius.circular(16), // Reduced from 20
                          ),
                          child: TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAllFiles = !_showAllFiles;
                              });
                            },
                            icon: Icon(
                              _showAllFiles
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: const Color(0xFF3B82F6),
                              size: 16, // Reduced from 18
                            ),
                            label: Text(
                              _showAllFiles
                                  ? 'Show Less'
                                  : 'Show All (${_tempFiles.length})',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                                fontSize: 12, // Reduced from 14
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16), // Reduced from 24
                    SizedBox(
                      height: _showAllFiles ? 300 : 150, // Reduced from 400/200
                      child: ListView.separated(
                        itemCount: _showAllFiles
                            ? _tempFiles.length
                            : _tempFiles.length.clamp(0, 8),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8), // Reduced from 12
                        itemBuilder: (context, index) {
                          FileSystemEntity entity = _tempFiles[index];
                          String fileName = entity.path.split('\\').last;
                          String folderPath = entity.parent.path;
                          bool isDirectory = entity is Directory;

                          return Container(
                            padding:
                                const EdgeInsets.all(12), // Reduced from 16
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius:
                                  BorderRadius.circular(8), // Reduced from 12
                              border: Border.all(
                                color: const Color(0xFFE5E7EB).withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.01), // Reduced opacity
                                  blurRadius: 2, // Reduced from 4
                                  offset: const Offset(0, 1), // Reduced from 2
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(
                                          6), // Reduced from 8
                                      decoration: BoxDecoration(
                                        color: isDirectory
                                            ? const Color(0xFF3B82F6)
                                                .withOpacity(0.1)
                                            : const Color(0xFF6B7280)
                                                .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(
                                            6), // Reduced from 8
                                      ),
                                      child: Icon(
                                        isDirectory
                                            ? Icons.folder
                                            : Icons.insert_drive_file,
                                        size: 14, // Reduced from 18
                                        color: isDirectory
                                            ? const Color(0xFF3B82F6)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 10), // Reduced from 12
                                    Expanded(
                                      child: Text(
                                        fileName,
                                        style: const TextStyle(
                                          fontSize: 13, // Reduced from 15
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6), // Reduced from 8
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4), // Reduced from 12, 6
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(
                                        4), // Reduced from 6
                                  ),
                                  child: Text(
                                    folderPath,
                                    style: const TextStyle(
                                      fontSize: 10, // Reduced from 12
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'monospace',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (!_showAllFiles && _tempFiles.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          '... and ${_tempFiles.length - 8} more items',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
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
    });

    for (String folder in _scannedFolders) {
      setState(() {
        _selectedFolder = folder;
      });

      try {
        String actualFolder = folder.replaceAll(
          '%USERNAME%',
          Platform.environment['USERNAME'] ?? 'User',
        );

        Directory directory = Directory(actualFolder);
        if (await directory.exists()) {
          await for (FileSystemEntity entity in directory.list()) {
            if (entity is File) {
              try {
                int fileSize = await entity.length();
                setState(() {
                  _tempFiles.add(entity);
                  _totalSize += fileSize;

                  // Group files by folder for organized display
                  String folderPath = entity.parent.path;
                  if (!_filesByFolder.containsKey(folderPath)) {
                    _filesByFolder[folderPath] = [];
                  }
                  _filesByFolder[folderPath]!.add(entity);
                });
              } catch (e) {
                // Skip files we can't access
              }
            }
          }
        }
      } catch (e) {
        print('Error scanning folder $folder: $e');
      }
    }

    setState(() {
      _isScanning = false;
      _selectedFolder = '';
    });
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
        // Remove from list even if deletion failed to avoid retry
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
    // Wait for scan to complete, then clean
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
        return const Color(0xFF9CA3AF); // Disabled: muted gray
      }
      return Colors.white; // All buttons have white text for better contrast
    }

    return MouseRegion(
      onEnter: isDisabled ? null : (_) => setState(() => _isHovered = true),
      onExit: isDisabled ? null : (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 40, // Reduced from 52
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
          borderRadius: BorderRadius.circular(8), // Reduced from 12
          boxShadow: isDisabled || !_isHovered
              ? []
              : [
                  BoxShadow(
                    color: widget.isPrimary
                        ? const Color(0xFF3B82F6)
                            .withOpacity(0.3) // Reduced opacity
                        : widget.isDestructive
                            ? const Color(0xFFEF4444)
                                .withOpacity(0.3) // Reduced opacity
                            : const Color(0xFF6366F1)
                                .withOpacity(0.3), // Reduced opacity
                    blurRadius: 8, // Reduced from 12
                    offset: const Offset(0, 2), // Reduced from 4
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(8), // Reduced from 12
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8), // Reduced from 16, 12
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.icon,
                    size: 16, // Reduced from 20
                    color: getTextColor(),
                  ),
                  const SizedBox(width: 6), // Reduced from 8
                  Text(
                    widget.text,
                    style: TextStyle(
                      fontSize: 13, // Reduced from 15
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
