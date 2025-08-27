import 'dart:io';

import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({
    super.key,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<String> tempFiles = [];
  bool _isLoading = false;
  String _loadingText = "";
  double _progress = 0.0;

  Future<void> scanTempFiles() async {
    setState(() {
      _isLoading = true;
      _loadingText = "Scanning files...";
      _progress = 0.0;
    });

    List<String> tempDirectories = [
      Platform.environment['TEMP']!,
      r'C:\Windows\Temp',
      r'C:\Windows\Prefetch',
    ];

    List<String> foundItems = [];
    int totalDirs = tempDirectories.length;

    for (int i = 0; i < tempDirectories.length; i++) {
      String dirPath = tempDirectories[i];
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          dir.listSync().forEach((FileSystemEntity entity) {
            if (entity is File) {
              foundItems.add('File: ${entity.path}');
            } else if (entity is Directory) {
              foundItems.add('Folder: ${entity.path}');
            }
          });
        } catch (e) {
          print('Error accessing $dirPath: $e');
          foundItems
              .add('Error accessing $dirPath: Requires Administrator Access');
        }
      }
      setState(() {
        _progress = (i + 1) / totalDirs;
      });
    }

    setState(() {
      tempFiles = foundItems;
      _isLoading = false;
      _loadingText = "";
      _progress = 0.0;
    });
  }

  Future<void> cleanTempFiles() async {
    setState(() {
      _isLoading = true;
      _loadingText = "Cleaning files...";
      _progress = 0.0;
    });

    final logFile = File('${Directory.current.path}\\log.txt');
    final now = DateTime.now();

    int total = tempFiles.length;
    if (total == 0) total = 1; // Prevent division by zero

    for (int i = 0; i < tempFiles.length; i++) {
      String itemPath = tempFiles[i];
      final file = File(itemPath.replaceFirst('File: ', ''));
      final folder = Directory(itemPath.replaceFirst('Folder: ', ''));

      try {
        if (itemPath.startsWith('File: ')) {
          if (file.existsSync()) {
            file.deleteSync();
            logFile.writeAsStringSync('$now - Deleted File: $itemPath\n',
                mode: FileMode.append);
            print('Deleted file: $itemPath');
          }
        } else if (itemPath.startsWith('Folder: ')) {
          if (folder.existsSync()) {
            folder.deleteSync(recursive: true);
            logFile.writeAsStringSync('$now - Deleted Folder: $itemPath\n',
                mode: FileMode.append);
            print('Deleted folder: $itemPath');
          }
        }
      } catch (e) {
        print('Failed to delete $itemPath: $e');
        logFile.writeAsStringSync(
            '$now - Failed to delete: $itemPath, Error: $e\n',
            mode: FileMode.append);
      }
      setState(() {
        _progress = (i + 1) / total;
      });
    }

    setState(() {
      tempFiles.clear();
      _isLoading = false;
      _loadingText = "";
      _progress = 0.0;
    });
  }

  void _showLogHistory() async {
    final logFile = File('${Directory.current.path}\\log.txt');
    List<String> logEntries = [];

    // Check if the log file exists and read its contents
    if (logFile.existsSync()) {
      logEntries = logFile.readAsLinesSync();
    } else {
      logEntries = ['No log data found.'];
    }

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white.withOpacity(0.07),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title with gradient icon
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                        ).createShader(bounds);
                      },
                      child: const Icon(Icons.history,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Log History',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    // Animated close button
                    _AnimatedCloseButton(),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: logEntries.isEmpty
                      ? Center(
                          child: Text(
                            "No log data found.",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: logEntries.length,
                          itemBuilder: (context, index) {
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: 1),
                              duration:
                                  Duration(milliseconds: 200 + index * 10),
                              builder: (context, value, child) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(0, (1 - value) * 20),
                                    child: child,
                                  ),
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      logEntries[index].contains('Deleted File')
                                          ? Icons.insert_drive_file
                                          : logEntries[index]
                                                  .contains('Deleted Folder')
                                              ? Icons.folder
                                              : Icons.info_outline,
                                      color: logEntries[index]
                                              .contains('Deleted File')
                                          ? Colors.lightBlueAccent
                                          : logEntries[index]
                                                  .contains('Deleted Folder')
                                              ? Colors.amberAccent
                                              : Colors.white70,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        logEntries[index],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🎨 Beautiful Header Card with cool and warm colors
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3B82F6), // Cool blue
                    Color(0xFF8B5CF6), // Warm purple
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // 🎨 Emoji icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🧹',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "System Cleaner",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Keep your system sparkling clean",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // 🎨 Action buttons with cool and warm colors
                  Row(
                    children: [
                      Expanded(
                        child: _AnimatedGradientButton(
                          onPressed: _isLoading ? null : _showLogHistory,
                          label: 'View Log',
                          icon: Icons.history,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF06B6D4),
                              Color(0xFF0891B2)
                            ], // Cool cyan
                          ),
                          disabled: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimatedGradientButton(
                          onPressed: _isLoading ? null : scanTempFiles,
                          label: 'Scan Files',
                          icon: Icons.search_rounded,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF10B981),
                              Color(0xFF059669)
                            ], // Cool green
                          ),
                          disabled: _isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _AnimatedGradientButton(
                          onPressed: (_isLoading || tempFiles.isEmpty)
                              ? null
                              : cleanTempFiles,
                          label: 'Clean Files',
                          icon: Icons.cleaning_services_rounded,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFEF4444)
                            ], // Warm amber to red
                          ),
                          disabled: _isLoading || tempFiles.isEmpty,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🎨 Progress section with cool colors
            if (_isLoading) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Cool light gray
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF6366F1), // Cool indigo
                                Color(0xFF8B5CF6), // Warm purple
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '⚡',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _loadingText,
                            style: const TextStyle(
                              color: Color(0xFF1F2937), // Cool dark gray
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "${(_progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            color: Color(0xFF6366F1), // Cool indigo
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF6366F1), // Cool indigo
                        ),
                        value: _progress,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // 🎨 Files list with cool background
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC), // Cool light gray
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: tempFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                '🔍',
                                style: TextStyle(fontSize: 48),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No files scanned yet',
                              style: TextStyle(
                                color: Color(0xFF1F2937), // Cool dark gray
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Click "Scan Files" to start cleaning!',
                              style: TextStyle(
                                color: Color(0xFF6B7280), // Warm gray
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: tempFiles.length,
                        itemBuilder: (context, index) {
                          bool isFile = tempFiles[index].startsWith('File: ');
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // 🎨 Beautiful file/folder icons with cool/warm gradients
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isFile
                                          ? [
                                              const Color(0xFF3B82F6),
                                              const Color(0xFF6366F1)
                                            ] // Cool blue to indigo
                                          : [
                                              const Color(0xFFF59E0B),
                                              const Color(0xFFEF4444)
                                            ], // Warm amber to red
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isFile
                                        ? Icons.description_rounded
                                        : Icons.folder_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // File path text
                                Expanded(
                                  child: Text(
                                    tempFiles[index].replaceFirst(
                                        isFile ? 'File: ' : 'Folder: ', ''),
                                    style: const TextStyle(
                                      color:
                                          Color(0xFF374151), // Cool dark gray
                                      fontSize: 13,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // File type indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isFile
                                        ? const Color(0xFF3B82F6)
                                            .withOpacity(0.1)
                                        : const Color(0xFFF59E0B)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isFile ? 'FILE' : 'FOLDER',
                                    style: TextStyle(
                                      color: isFile
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFF59E0B),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Update your _AnimatedGradientButton to accept a disabled property:
class _AnimatedGradientButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData icon;
  final Gradient gradient;
  final bool disabled;

  const _AnimatedGradientButton({
    required this.onPressed,
    required this.label,
    required this.icon,
    required this.gradient,
    this.disabled = false,
  });

  @override
  State<_AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.disabled || widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) {
        if (!isDisabled) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (!isDisabled) setState(() => _hovering = false);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_hovering && !isDisabled ? 1.08 : 1.0),
        decoration: BoxDecoration(
          boxShadow: _hovering && !isDisabled
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDisabled
                ? Colors.white.withOpacity(0.15)
                : _hovering
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white.withOpacity(0.4),
            width: _hovering && !isDisabled ? 2 : 1,
          ),
        ),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            side: BorderSide.none,
          ),
          onPressed: isDisabled ? null : widget.onPressed,
          icon: ShaderMask(
            shaderCallback: (Rect bounds) {
              return widget.gradient
                  .createShader(const Rect.fromLTWH(0, 0, 24, 24));
            },
            child: Icon(
              widget.icon,
              color: isDisabled ? Colors.white38 : Colors.white,
            ),
          ),
          label: Text(
            widget.label,
            style: TextStyle(
              color: isDisabled ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// Add this widget below your Homepage class in the same file:
class _AnimatedCloseButton extends StatefulWidget {
  @override
  State<_AnimatedCloseButton> createState() => _AnimatedCloseButtonState();
}

class _AnimatedCloseButtonState extends State<_AnimatedCloseButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovering
                ? Colors.redAccent.withOpacity(0.18)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.close,
            color: _hovering ? Colors.redAccent : Colors.white70,
            size: 24,
          ),
        ),
      ),
    );
  }
}
