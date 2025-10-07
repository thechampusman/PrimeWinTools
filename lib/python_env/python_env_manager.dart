import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

class PythonEnvironment {
  String id;
  String name;
  String originalName;
  String path;
  String type;
  String pythonVersion;
  int packageCount;
  DateTime? lastUsed;
  DateTime? createdDate;
  int sizeOnDisk;

  PythonEnvironment({
    required this.id,
    required this.name,
    required this.originalName,
    required this.path,
    required this.type,
    this.pythonVersion = 'Unknown',
    this.packageCount = 0,
    this.lastUsed,
    this.createdDate,
    this.sizeOnDisk = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'originalName': originalName,
        'path': path,
        'type': type,
        'pythonVersion': pythonVersion,
        'packageCount': packageCount,
        'lastUsed': lastUsed?.toIso8601String(),
        'createdDate': createdDate?.toIso8601String(),
        'sizeOnDisk': sizeOnDisk,
      };

  factory PythonEnvironment.fromJson(Map<String, dynamic> json) =>
      PythonEnvironment(
        id: json['id'],
        name: json['name'],
        originalName: json['originalName'],
        path: json['path'],
        type: json['type'],
        pythonVersion: json['pythonVersion'] ?? 'Unknown',
        packageCount: json['packageCount'] ?? 0,
        lastUsed:
            json['lastUsed'] != null ? DateTime.parse(json['lastUsed']) : null,
        createdDate: json['createdDate'] != null
            ? DateTime.parse(json['createdDate'])
            : null,
        sizeOnDisk: json['sizeOnDisk'] ?? 0,
      );
}

class PythonEnvManager extends StatefulWidget {
  const PythonEnvManager({super.key});

  @override
  State<PythonEnvManager> createState() => _PythonEnvManagerState();
}

class _PythonEnvManagerState extends State<PythonEnvManager> {
  List<PythonEnvironment> _environments = [];
  List<PythonEnvironment> _filteredEnvironments = [];
  bool _isScanning = false;
  String _scanStatus = '';
  String _currentScanLocation = '';
  int _scanProgress = 0;
  int _totalScanCount = 0;
  String _searchQuery = '';
  String _filterType = 'all';
  bool _cancelRequested = false;

  @override
  void initState() {
    super.initState();
    _loadCachedEnvironments();
  }

  Future<File> _getCacheFile() async {
    final appDir = Directory.current;
    final cacheDir = Directory('${appDir.path}\\cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return File('${cacheDir.path}\\python_environments.json');
  }

  Future<void> _loadCachedEnvironments() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        final jsonString = await cacheFile.readAsString();
        final jsonData = jsonDecode(jsonString);

        final allEnvironments = (jsonData['environments'] as List)
            .map((env) => PythonEnvironment.fromJson(env))
            .toList();

        // Validate environments asynchronously
        final validEnvironments = <PythonEnvironment>[];
        for (final env in allEnvironments) {
          if (await _validateEnvironment(env)) {
            validEnvironments.add(env);
          }
        }

        // Final deduplication step for cached environments
        final deduplicatedEnvironments =
            _deduplicateEnvironments(validEnvironments);

        setState(() {
          _environments = deduplicatedEnvironments;
          _updateFilteredEnvironments();
        });

        print('Loaded ${_environments.length} environments from cache');

        // Show a brief message that data was loaded from cache
        if (_environments.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.cached, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                        'Loaded ${_environments.length} environments from cache'),
                  ],
                ),
                backgroundColor: Color(0xFF306998),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          });
        }
      } else {
        setState(() {
          _environments = [];
        });
        print('No cache file found, starting with empty environment list');
      }
    } catch (e) {
      print('Error loading cached environments: $e');
      setState(() {
        _environments = [];
      });
    }
  }

  Future<bool> _validateEnvironment(PythonEnvironment env) async {
    try {
      // Check if the environment path still exists
      final envDir = Directory(env.path);
      if (!await envDir.exists()) {
        return false;
      }

      // Check if activation script still exists
      final scriptPaths = [
        '${env.path}\\Scripts\\activate.ps1',
        '${env.path}\\Scripts\\activate.bat',
        '${env.path}\\bin\\activate',
      ];

      for (final scriptPath in scriptPaths) {
        if (await File(scriptPath).exists()) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveCachedEnvironments() async {
    try {
      final cacheFile = await _getCacheFile();
      final cacheData = {
        'lastUpdated': DateTime.now().toIso8601String(),
        'totalCount': _environments.length,
        'environments': _environments.map((env) => env.toJson()).toList(),
      };

      await cacheFile.writeAsString(jsonEncode(cacheData));
      print('Saved ${_environments.length} environments to cache');
    } catch (e) {
      print('Error saving environments to cache: $e');
    }
  }

  Future<DateTime?> _getCacheLastUpdated() async {
    try {
      final cacheFile = await _getCacheFile();
      if (await cacheFile.exists()) {
        final jsonString = await cacheFile.readAsString();
        final jsonData = jsonDecode(jsonString);
        return DateTime.parse(jsonData['lastUpdated']);
      }
    } catch (e) {
      print('Error getting cache date: $e');
    }
    return null;
  }

  Future<void> _showCacheInfo() async {
    final cacheFile = await _getCacheFile();
    final cacheExists = await cacheFile.exists();

    String cacheInfo;
    if (cacheExists) {
      final lastUpdated = await _getCacheLastUpdated();
      final fileSize = await cacheFile.length();
      final fileSizeKB = (fileSize / 1024).toStringAsFixed(1);

      cacheInfo = '''Cache Information:
• Status: Active
• Environments: ${_environments.length} cached
• Last Updated: ${lastUpdated?.toString().split('.')[0] ?? 'Unknown'}
• File Size: ${fileSizeKB}KB
• Location: ${cacheFile.path}

The cache helps avoid re-scanning your system every time you open the app.''';
    } else {
      cacheInfo = '''Cache Information:
• Status: No cache found
• Environments: 0 cached
• Location: ${cacheFile.path}

Run a scan to build the environment cache and speed up future app launches.''';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.storage, color: Color(0xFF306998)),
              SizedBox(width: 8),
              Text('Environment Cache'),
            ],
          ),
          content: Container(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cacheInfo),
                if (cacheExists) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.blue[700], size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Cache automatically validates environments on app startup and removes invalid ones.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close'),
            ),
            if (cacheExists)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _clearCache();
                },
                icon: Icon(Icons.clear_all, size: 16),
                label: Text('Clear Cache'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Clear Cache'),
            ],
          ),
          content: Text(
            'Are you sure you want to clear the environment cache?\n\nThis will remove all cached environment data and require a fresh scan next time.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: Text('Clear Cache'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final cacheFile = await _getCacheFile();
        if (await cacheFile.exists()) {
          await cacheFile.delete();
        }

        setState(() {
          _environments.clear();
          _updateFilteredEnvironments();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cache cleared successfully!'),
            backgroundColor: Color(0xFF4CAF50),
            action: SnackBarAction(
              label: 'Scan Now',
              textColor: Colors.white,
              onPressed: () => _showScanOptionsDialog(),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showScanOptionsDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return ScanOptionsDialog();
      },
    );

    if (result != null) {
      await _scanEnvironments(
        scanType: result['scanType'],
        customPaths: result['customPaths'],
      );
    }
  }

  Future<void> _scanEnvironments({
    required String scanType,
    List<String>? customPaths,
  }) async {
    setState(() {
      _isScanning = true;
      _scanStatus = 'Initializing scan...';
      _currentScanLocation = '';
      _scanProgress = 0;
      _totalScanCount = 0;
      _environments.clear();
      _cancelRequested = false;
    });

    try {
      List<String> searchPaths = [];

      if (scanType == 'full') {
        // Get all local drives
        searchPaths = await _getLocalDrives();
      } else if (scanType == 'custom' && customPaths != null) {
        searchPaths = customPaths;
      }

      setState(() {
        _scanStatus = 'Scanning ${searchPaths.length} location(s)...';
      });

      Map<String, PythonEnvironment> uniqueEnvironments = {};

      for (int i = 0; i < searchPaths.length; i++) {
        if (_cancelRequested) break;
        final path = searchPaths[i];
        setState(() {
          _scanStatus = 'Scanning location ${i + 1} of ${searchPaths.length}';
          _currentScanLocation = path;
          _scanProgress = ((i + 1) / searchPaths.length * 100).round();
        });

        final envs = await _scanPathForEnvironments(path);
        if (_cancelRequested) break;

        // Deduplicate environments based on path
        for (final env in envs) {
          final envPath = env.path.toLowerCase().replaceAll('/', '\\');
          if (!uniqueEnvironments.containsKey(envPath)) {
            uniqueEnvironments[envPath] = env;
            print(
                'Added new environment: ${env.name} (${env.type}) at ${env.path}');
          } else if (_isBetterEnvironment(env, uniqueEnvironments[envPath]!)) {
            print(
                'Replaced duplicate environment at ${env.path}: ${uniqueEnvironments[envPath]!.type} → ${env.type}');
            uniqueEnvironments[envPath] = env;
          } else {
            print(
                'Skipped duplicate environment: ${env.name} (${env.type}) at ${env.path}');
          }
        }

        setState(() {
          _environments = uniqueEnvironments.values.toList();
          _totalScanCount = uniqueEnvironments.length;
          _updateFilteredEnvironments();
        });
      }

      final foundEnvironments = uniqueEnvironments.values.toList();

      setState(() {
        _environments = foundEnvironments;
        _updateFilteredEnvironments();
      });

      if (!_cancelRequested) {
        setState(() {
          _scanStatus = 'Saving to cache...';
        });
        await _saveCachedEnvironments();
      }

      setState(() {
        _scanStatus = _cancelRequested
            ? 'Scan cancelled - ${foundEnvironments.length} environments found so far'
            : 'Scan completed - ${foundEnvironments.length} unique environments found';
      });

      await Future.delayed(Duration(seconds: 2));
    } catch (e) {
      setState(() {
        _scanStatus = 'Scan failed: $e';
      });
    } finally {
      setState(() {
        _isScanning = false;
        _scanStatus = '';
        _currentScanLocation = '';
        _scanProgress = 0;
      });
    }
  }

  void _stopScanning() {
    if (_isScanning && !_cancelRequested) {
      setState(() {
        _cancelRequested = true;
        _scanStatus = 'Cancelling...';
      });
    }
  }

  Future<List<String>> _getLocalDrives() async {
    List<String> searchPaths = [];

    try {
      // First, add common Python environment locations for faster scanning
      final commonPaths = await _getCommonPythonPaths();
      searchPaths.addAll(commonPaths);

      // Then add all drives for comprehensive scan
      for (String drive in [
        'C:',
        'D:',
        'E:',
        'F:',
        'G:',
        'H:',
        'I:',
        'J:',
        'K:',
        'L:',
        'M:',
        'N:',
        'O:',
        'P:',
        'Q:',
        'R:',
        'S:',
        'T:',
        'U:',
        'V:',
        'W:',
        'X:',
        'Y:',
        'Z:'
      ]) {
        final dir = Directory('$drive\\');
        if (await dir.exists()) {
          final drivePath = '$drive\\';
          if (!searchPaths.contains(drivePath)) {
            searchPaths.add(drivePath);
          }
        }
      }
    } catch (e) {
      print('Error getting drives: $e');
    }

    return searchPaths;
  }

  Future<List<String>> _getCommonPythonPaths() async {
    List<String> paths = [];

    try {
      // Get user directory
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        // Common conda locations
        final condaPath = '$userProfile\\anaconda3';
        if (await Directory(condaPath).exists()) {
          paths.add(condaPath);
        }

        final minicondaPath = '$userProfile\\miniconda3';
        if (await Directory(minicondaPath).exists()) {
          paths.add(minicondaPath);
        }

        // Common project directories
        final projectDirs = [
          '$userProfile\\Documents',
          '$userProfile\\Desktop',
          'C:\\Projects',
          'D:\\Projects',
          'C:\\Development',
          'D:\\Development',
          'C:\\Code',
          'D:\\Code',
          'D:\\PersonalProjects', // Your specific case!
        ];

        for (final dir in projectDirs) {
          if (await Directory(dir).exists()) {
            paths.add(dir);
          }
        }
      }

      // System-wide Python locations (check if they exist)
      final systemDirs = [
        'C:\\Program Files\\Python39',
        'C:\\Program Files\\Python310',
        'C:\\Program Files\\Python311',
        'C:\\Program Files\\Python312',
        'C:\\Program Files (x86)\\Python39',
        'C:\\Program Files (x86)\\Python310',
        'C:\\Program Files (x86)\\Python311',
        'C:\\Program Files (x86)\\Python312',
      ];

      for (final dir in systemDirs) {
        if (await Directory(dir).exists()) {
          paths.add(dir);
        }
      }
    } catch (e) {
      print('Error getting common Python paths: $e');
    }

    return paths;
  }

  Future<List<PythonEnvironment>> _scanPathForEnvironments(
      String basePath) async {
    List<PythonEnvironment> environments = [];

    try {
      // Search for activation scripts using common patterns
      final activationScripts = await _findActivationScripts(basePath);

      for (final scriptPath in activationScripts) {
        try {
          final env = await _analyzeEnvironment(scriptPath);
          if (env != null) {
            environments.add(env);
          }
        } catch (e) {
          print('Error analyzing environment at $scriptPath: $e');
        }
      }
    } catch (e) {
      print('Error scanning path $basePath: $e');
    }

    return environments;
  }

  Future<List<String>> _findActivationScripts(String basePath) async {
    List<String> scripts = [];

    try {
      final directory = Directory(basePath);
      await _scanDirectoryRecursively(directory, scripts);
    } catch (e) {
      // Ignore access denied errors and continue
      print('Access denied or error in $basePath: $e');
    }

    return scripts;
  }

  Future<void> _scanDirectoryRecursively(
      Directory directory, List<String> scripts) async {
    try {
      if (_cancelRequested) return;
      final entities = await directory.list(followLinks: false).toList();

      for (final entity in entities) {
        if (_cancelRequested) return;
        try {
          if (entity is File) {
            final path = entity.path;
            // Look for common activation script patterns
            if (_isActivationScript(path)) {
              scripts.add(path);
              // Update UI with found environment
              setState(() {
                _totalScanCount = scripts.length;
              });
            }
          } else if (entity is Directory) {
            if (_cancelRequested) return;
            final dirName = entity.path.toLowerCase();

            // Skip known system/protected directories to avoid access denied errors
            if (_shouldSkipDirectory(dirName)) {
              continue;
            }

            // Update current location for deeper scans (only for non-root directories)
            final currentPath = entity.path;
            if (currentPath.length > _currentScanLocation.length + 50) {
              setState(() {
                _currentScanLocation = currentPath;
              });
            }

            // Recursively scan subdirectories
            await _scanDirectoryRecursively(entity, scripts);
          }
        } catch (e) {
          // Skip individual files/folders that can't be accessed
          continue;
        }
      }
    } catch (e) {
      // Skip entire directory if it can't be accessed
      if (!e.toString().contains('Access is denied')) {
        print('Skipping directory ${directory.path}: $e');
      }
    }
  }

  bool _shouldSkipDirectory(String dirPath) {
    final skipPatterns = [
      r'\$recycle.bin',
      r'\system volume information',
      r'\windows\system32',
      r'\windows\syswow64',
      r'\windows\winsxs',
      r'\programdata\microsoft',
      r'\users\all users',
      r'\users\default',
      r'\recovery',
      r'\boot',
      r'\efi',
      r'\.git',
      r'\.svn',
      r'\node_modules',
      r'\__pycache__',
      r'\.pytest_cache',
      r'\.mypy_cache',
      r'\temp',
      r'\tmp',
      r'\cache',
    ];

    for (final pattern in skipPatterns) {
      if (dirPath.contains(pattern)) {
        return true;
      }
    }

    return false;
  }

  bool _isBetterEnvironment(
      PythonEnvironment newEnv, PythonEnvironment existingEnv) {
    // Prefer environments with known Python versions
    if (newEnv.pythonVersion != 'Unknown' &&
        existingEnv.pythonVersion == 'Unknown') {
      return true;
    }
    if (newEnv.pythonVersion == 'Unknown' &&
        existingEnv.pythonVersion != 'Unknown') {
      return false;
    }

    // Prefer environments with more packages
    if (newEnv.packageCount > existingEnv.packageCount) {
      return true;
    }
    if (newEnv.packageCount < existingEnv.packageCount) {
      return false;
    }

    // Prefer specific environment types (conda > poetry > pipenv > venv)
    final typePreference = {
      'conda': 4,
      'poetry': 3,
      'pipenv': 2,
      'venv': 1,
      'virtualenv': 1,
    };

    final newTypePref = typePreference[newEnv.type.toLowerCase()] ?? 0;
    final existingTypePref =
        typePreference[existingEnv.type.toLowerCase()] ?? 0;

    if (newTypePref != existingTypePref) {
      return newTypePref > existingTypePref;
    }

    // If all else is equal, keep the existing one (first found)
    return false;
  }

  List<PythonEnvironment> _deduplicateEnvironments(
      List<PythonEnvironment> environments) {
    Map<String, PythonEnvironment> uniqueEnvironments = {};

    for (final env in environments) {
      final envPath = env.path.toLowerCase().replaceAll('/', '\\');
      if (!uniqueEnvironments.containsKey(envPath) ||
          _isBetterEnvironment(env, uniqueEnvironments[envPath]!)) {
        uniqueEnvironments[envPath] = env;
      }
    }

    final originalCount = environments.length;
    final deduplicatedCount = uniqueEnvironments.length;

    if (originalCount != deduplicatedCount) {
      print(
          'Deduplicated environments: $originalCount → $deduplicatedCount (removed ${originalCount - deduplicatedCount} duplicates)');
    }

    return uniqueEnvironments.values.toList();
  }

  String _generateSmartEnvironmentName(String envPath, String envType) {
    // Get the folder name
    String folderName = envPath.split('\\').last;

    // Handle common patterns for better naming
    if (folderName.isEmpty) {
      return 'Unknown Environment';
    }

    // Handle common virtual environment folder names
    if (folderName.toLowerCase() == 'venv' ||
        folderName.toLowerCase() == '.venv' ||
        folderName.toLowerCase() == 'env' ||
        folderName.toLowerCase() == '.env') {
      // Use parent directory name for common venv folder names
      final pathParts = envPath.split('\\');
      if (pathParts.length >= 2) {
        final parentFolder = pathParts[pathParts.length - 2];
        return _cleanEnvironmentName(parentFolder);
      }
    }

    // Handle conda environments (usually have descriptive names already)
    if (envType.toLowerCase() == 'conda') {
      return _cleanEnvironmentName(folderName);
    }

    // Handle poetry/pipenv (use project folder name)
    if (envType.toLowerCase() == 'poetry' ||
        envType.toLowerCase() == 'pipenv') {
      return _cleanEnvironmentName(folderName);
    }

    // For other cases, use the folder name directly
    return _cleanEnvironmentName(folderName);
  }

  String _cleanEnvironmentName(String name) {
    // Remove common prefixes/suffixes and clean up the name
    String cleaned = name;

    // Remove leading dots
    while (cleaned.startsWith('.') && cleaned.length > 1) {
      cleaned = cleaned.substring(1);
    }

    // Remove common suffixes
    const suffixes = [
      '-venv',
      '_venv',
      '-env',
      '_env',
      '-virtualenv',
      '_virtualenv'
    ];
    for (final suffix in suffixes) {
      if (cleaned.toLowerCase().endsWith(suffix.toLowerCase())) {
        cleaned = cleaned.substring(0, cleaned.length - suffix.length);
        break;
      }
    }

    // Convert underscores and hyphens to spaces for readability
    cleaned = cleaned.replaceAll('_', ' ').replaceAll('-', ' ');

    // Capitalize first letter of each word
    if (cleaned.isNotEmpty) {
      cleaned = cleaned.split(' ').map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }).join(' ');
    }

    return cleaned.isEmpty ? 'Environment' : cleaned;
  }

  Widget _buildNameSuggestion(
      String suggestion, TextEditingController controller) {
    if (suggestion.isEmpty || suggestion == controller.text) {
      return SizedBox.shrink();
    }

    return InkWell(
      onTap: () {
        controller.text = suggestion;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          suggestion,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _updateFilteredEnvironments() {
    setState(() {
      _filteredEnvironments = _environments.where((env) {
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            env.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            env.path.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            env.type.toLowerCase().contains(_searchQuery.toLowerCase());

        // Apply type filter
        bool matchesType = _filterType == 'all' ||
            env.type.toLowerCase() == _filterType.toLowerCase() ||
            (_filterType == 'venv' &&
                (env.type.toLowerCase() == 'virtualenv' ||
                    env.type.toLowerCase() == 'venv'));

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _editEnvironmentName(PythonEnvironment env) async {
    final TextEditingController nameController =
        TextEditingController(text: env.name);

    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF306998)),
              SizedBox(width: 8),
              Text('Edit Environment Name'),
            ],
          ),
          content: Container(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Environment Info Section
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: _getEnvironmentColor(env.type)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              _getEnvironmentIcon(env.type),
                              size: 16,
                              color: _getEnvironmentColor(env.type),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current Name: ${env.name}',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Folder: ${env.originalName}',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Path: ${env.path}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),

                // Name Input Section
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Environment Alias',
                    hintText: 'Enter a friendly name for this environment',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Color(0xFF306998)),
                    ),
                    prefixIcon: Icon(Icons.label_outline),
                    suffixIcon: nameController.text != env.originalName
                        ? Icon(Icons.edit, color: Color(0xFF306998), size: 16)
                        : null,
                  ),
                  autofocus: true,
                  maxLength: 50,
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      Navigator.of(context).pop(value.trim());
                    }
                  },
                ),
                SizedBox(height: 8),

                // Quick Name Suggestions
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildNameSuggestion(env.originalName, nameController),
                    _buildNameSuggestion(
                        _cleanEnvironmentName(env.originalName),
                        nameController),
                    if (env.type.toLowerCase() != 'venv')
                      _buildNameSuggestion(
                          '${env.type} ${_cleanEnvironmentName(env.originalName)}',
                          nameController),
                  ],
                ),
                SizedBox(height: 12),

                // Info Section
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 16, color: Colors.blue[700]),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Custom names help you identify environments quickly. They\'re saved locally and don\'t affect the actual environment.',
                          style:
                              TextStyle(fontSize: 12, color: Colors.blue[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Reset to original name
                Navigator.of(context).pop(env.originalName);
              },
              child: Text('Reset'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty) {
                  Navigator.of(context).pop(newName);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF306998),
                foregroundColor: Colors.white,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        final index = _environments.indexWhere((e) => e.id == env.id);
        if (index != -1) {
          _environments[index].name = result;
        }
      });

      // Save to cache with updated name
      await _saveCachedEnvironments();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Environment name updated to "$result"'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  bool _isActivationScript(String filePath) {
    final fileName = filePath.toLowerCase();

    // Check for various activation script patterns
    return (fileName.endsWith('\\scripts\\activate.ps1') ||
        fileName.endsWith('\\scripts\\activate.bat') ||
        fileName.endsWith('\\scripts\\activate') ||
        fileName.endsWith('\\bin\\activate') ||
        fileName.contains('\\activate.ps1') ||
        fileName.contains('\\activate.bat') ||
        (fileName.contains('\\scripts\\') && fileName.contains('activate')) ||
        (fileName.contains('\\bin\\') && fileName.contains('activate')));
  }

  Future<PythonEnvironment?> _analyzeEnvironment(
      String activationScriptPath) async {
    try {
      final scriptFile = File(activationScriptPath);
      final scriptDir = scriptFile.parent;

      // Determine environment path (usually parent of Scripts/bin folder)
      Directory envDir;
      String envType = 'venv';

      if (scriptDir.path.toLowerCase().endsWith('scripts')) {
        envDir = scriptDir.parent;
      } else if (scriptDir.path.toLowerCase().endsWith('bin')) {
        envDir = scriptDir.parent;
      } else {
        envDir = scriptDir;
      }

      // Determine environment type
      if (envDir.path.toLowerCase().contains('anaconda') ||
          envDir.path.toLowerCase().contains('miniconda') ||
          await File('${envDir.path}\\conda-meta').exists() ||
          await Directory('${envDir.path}\\conda-meta').exists()) {
        envType = 'conda';
      } else if (await File('${envDir.path}\\Pipfile').exists()) {
        envType = 'pipenv';
      } else if (await File('${envDir.path}\\pyproject.toml').exists()) {
        final pyprojectContent =
            await File('${envDir.path}\\pyproject.toml').readAsString();
        if (pyprojectContent.contains('[tool.poetry]')) {
          envType = 'poetry';
        }
      }

      // Get environment name (smart alias generation)
      String envName = _generateSmartEnvironmentName(envDir.path, envType);
      String originalName = envDir.path.split('\\').last;

      // Try to get Python version
      String pythonVersion = 'Unknown';
      final pythonExe = File('${scriptDir.path}\\python.exe');
      if (await pythonExe.exists()) {
        try {
          final result = await Process.run(pythonExe.path, ['--version']);
          if (result.exitCode == 0) {
            final versionOutput = result.stdout.toString().trim();
            final versionMatch =
                RegExp(r'Python (\d+\.\d+\.\d+)').firstMatch(versionOutput);
            if (versionMatch != null) {
              pythonVersion = versionMatch.group(1)!;
            }
          }
        } catch (e) {
          print('Error getting Python version: $e');
        }
      }

      // Count packages (estimate from site-packages)
      int packageCount = 0;
      final sitePackagesDir = Directory('${envDir.path}\\Lib\\site-packages');
      if (await sitePackagesDir.exists()) {
        try {
          final packages = await sitePackagesDir
              .list()
              .where((entity) => entity is Directory)
              .length;
          packageCount = packages;
        } catch (e) {
          print('Error counting packages: $e');
        }
      }

      // Calculate environment size (in MB)
      int sizeOnDisk = await _calculateDirectorySize(envDir);

      return PythonEnvironment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: envName,
        originalName: originalName,
        path: envDir.path,
        type: envType,
        pythonVersion: pythonVersion,
        packageCount: packageCount,
        sizeOnDisk: sizeOnDisk,
        createdDate: await _getDirectoryCreationTime(envDir),
      );
    } catch (e) {
      print('Error analyzing environment: $e');
      return null;
    }
  }

  Future<DateTime?> _getDirectoryCreationTime(Directory dir) async {
    try {
      final stat = await dir.stat();
      return stat.changed;
    } catch (e) {
      return null;
    }
  }

  Future<int> _calculateDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      await for (final entity
          in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            final fileStat = await entity.stat();
            totalSize += fileStat.size;
          } catch (e) {
            // Skip files that can't be accessed
            continue;
          }
        }
      }
      // Return size in MB
      return (totalSize / (1024 * 1024)).round();
    } catch (e) {
      print('Error calculating directory size for ${dir.path}: $e');
      return 0;
    }
  }

  Future<void> _activateEnvironment(PythonEnvironment env) async {
    try {
      String activationScript = '';

      // Find the activation script based on environment type and OS
      if (env.type.toLowerCase() == 'conda') {
        activationScript = '${env.path}\\Scripts\\activate.bat';
      } else {
        // For venv, virtualenv, pipenv, poetry
        activationScript = '${env.path}\\Scripts\\activate.ps1';
        if (!await File(activationScript).exists()) {
          activationScript = '${env.path}\\Scripts\\activate.bat';
        }
      }

      if (await File(activationScript).exists()) {
        // Show activation dialog with command
        _showActivationDialog(env, activationScript);
      } else {
        _showErrorDialog('Activation script not found',
            'Could not find activation script for ${env.name} at expected location:\\n$activationScript');
      }
    } catch (e) {
      _showErrorDialog(
          'Activation Error', 'Failed to activate environment: $e');
    }
  }

  void _showActivationDialog(PythonEnvironment env, String activationScript) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final psScript = '${env.path}\\Scripts\\Activate.ps1';
        final batScript = '${env.path}\\Scripts\\activate.bat';
        final hasPs = File(psScript).existsSync();
        final hasBat = File(batScript).existsSync();

        final psCommand = '& "${psScript}"';
        final cmdCommand = '"${batScript}"';

        // Removed direct terminal open helpers for a cleaner dialog

        Color accent = const Color(0xFF306998); // Python blue
        Color success = const Color(0xFF4CAF50);
        Color subtleBg = const Color(0xFFF8F9FA);
        Color border = const Color(0xFFE0E0E0);

        Widget commandCard({
          required IconData icon,
          required String label,
          required String command,
          required bool available,
          required Color color,
        }) {
          return Opacity(
            opacity: available ? 1 : 0.5,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Spacer(),
                      Tooltip(
                        message: 'Copy command',
                        child: ElevatedButton.icon(
                          onPressed: available
                              ? () {
                                  Clipboard.setData(
                                      ClipboardData(text: command));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Command copied'),
                                      backgroundColor: success,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              : null,
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            textStyle: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: subtleBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: border),
                    ),
                    child: SelectableText(
                      command,
                      style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFF374151)),
                    ),
                  ),
                  if (!available) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Command not available for this environment.',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 640,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [
                        accent.withOpacity(0.95),
                        accent.withOpacity(0.75)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child:
                            const Icon(Icons.play_arrow, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Activate Environment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(env.name,
                                      style: TextStyle(
                                          color:
                                              Colors.white.withOpacity(0.95))),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    env.type.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Environment quick info
                        Row(
                          children: [
                            Icon(Icons.folder,
                                size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                env.path,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF4B5563)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (env.pythonVersion.isNotEmpty &&
                            env.pythonVersion != 'Unknown')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: accent.withOpacity(0.25)),
                            ),
                            child: Text(
                              'Python ${env.pythonVersion}',
                              style: const TextStyle(
                                color: Color(0xFF255E85),
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        const SizedBox(height: 16),
                        const Text(
                          'Use one of the following commands to activate this environment:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),

                        // Commands Grid - simplified layout
                        Column(
                          children: [
                            if (hasPs)
                              commandCard(
                                icon: Icons.terminal,
                                label: 'PowerShell',
                                command: psCommand,
                                available: hasPs,
                                color: const Color(0xFF0078D4),
                              ),
                            if (hasPs && hasBat) const SizedBox(height: 12),
                            if (hasBat)
                              commandCard(
                                icon: Icons.code,
                                label: 'Command Prompt',
                                command: cmdCommand,
                                available: hasBat,
                                color: const Color(0xFF2E7D32),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!hasPs && !hasBat)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              border:
                                  Border.all(color: const Color(0xFFFFCC80)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFF57C00), size: 16),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No activation script was detected. The environment may be invalid or moved.',
                                    style: TextStyle(
                                        fontSize: 12, color: Color(0xFF6D4C41)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // Removed Open PowerShell/Open CMD buttons as requested
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openFolderLocation(env);
                        },
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Open Folder'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.purple[600],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFolderLocation(PythonEnvironment env) async {
    try {
      // Open the environment folder in Windows Explorer
      await Process.start(
        'explorer',
        [env.path],
        mode: ProcessStartMode.detached,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.folder_open, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Opened folder location for "${env.name}"'),
              ),
            ],
          ),
          backgroundColor: Colors.purple[600],
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text('Failed to open folder: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _showEnvironmentDetails(PythonEnvironment env) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Color base = _getEnvironmentColor(env.type);

        Widget infoChip({
          required IconData icon,
          required String label,
          required String value,
          Color? color,
        }) {
          final Color c = color ?? base;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: c),
                const SizedBox(width: 6),
                Text(
                  '$label: ',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                ),
              ],
            ),
          );
        }

        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 680,
            constraints: const BoxConstraints(maxHeight: 760),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      colors: [base.withOpacity(0.95), base.withOpacity(0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_getEnvironmentIcon(env.type),
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(env.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                )),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Text(
                                    env.type.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Path with copy
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder,
                                size: 16, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Tooltip(
                                message: env.path,
                                child: Text(
                                  env.path,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF374151),
                                      fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                Clipboard.setData(
                                    ClipboardData(text: env.path));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Path copied to clipboard'),
                                    backgroundColor: Color(0xFF4CAF50),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy Path'),
                              style:
                                  TextButton.styleFrom(foregroundColor: base),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Info Chips
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            infoChip(
                                icon: Icons.code,
                                label: 'Python',
                                value: env.pythonVersion),
                            infoChip(
                                icon: Icons.apps,
                                label: 'Packages',
                                value: '${env.packageCount}'),
                            infoChip(
                              icon: Icons.sd_storage,
                              label: 'Size',
                              value: env.sizeOnDisk > 0
                                  ? '${env.sizeOnDisk} MB'
                                  : 'Calculating...',
                            ),
                            if (env.createdDate != null)
                              infoChip(
                                icon: Icons.event,
                                label: 'Created',
                                value:
                                    env.createdDate!.toString().split('.')[0],
                              ),
                            if (env.lastUsed != null)
                              infoChip(
                                icon: Icons.history,
                                label: 'Last Used',
                                value: env.lastUsed!.toString().split('.')[0],
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        // Original name
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge,
                                  size: 16, color: Color(0xFF6B7280)),
                              const SizedBox(width: 8),
                              const Text('Original Name:',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(env.originalName,
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _activateEnvironment(env);
                        },
                        icon: const Icon(Icons.play_arrow, size: 16),
                        label: const Text('Activate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openFolderLocation(env);
                        },
                        icon: const Icon(Icons.folder_open, size: 16),
                        label: const Text('Open Folder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // removed _buildDetailRow (replaced by styled chips and sections)

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.folder_special,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Python Environment Manager',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isScanning && _currentScanLocation.isNotEmpty
                          ? 'Currently scanning: $_currentScanLocation'
                          : 'Manage all your Python environments from one place',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isScanning
                            ? const Color(0xFF306998)
                            : Colors.grey[600],
                        fontWeight:
                            _isScanning ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _showScanOptionsDialog,
                    icon: _isScanning
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Icons.search),
                    label:
                        Text(_isScanning ? 'Scanning...' : 'Scan Environments'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF306998),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isScanning ? null : _showCacheInfo,
                    icon: Icon(Icons.info_outline),
                    tooltip: 'Cache Information',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _isScanning ? null : _clearCache,
                    icon: Icon(Icons.clear_all),
                    tooltip: 'Clear Cache',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red[50],
                      foregroundColor: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Section (when scanning)
          if (_isScanning)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF306998).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF306998).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF306998)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _scanStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF306998),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Found: $_totalScanCount',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF306998),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: _cancelRequested ? null : _stopScanning,
                        icon: Icon(Icons.stop_circle_outlined,
                            color: _cancelRequested
                                ? Colors.grey
                                : Colors.red[700]),
                        label: Text(
                          _cancelRequested ? 'Cancelling…' : 'Stop',
                          style: TextStyle(
                            color: _cancelRequested
                                ? Colors.grey
                                : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          backgroundColor: _cancelRequested
                              ? Colors.grey[200]
                              : Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _scanProgress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF306998)),
                  ),
                  const SizedBox(height: 8),
                  if (_currentScanLocation.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFF306998).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.folder_outlined,
                            size: 16,
                            color: const Color(0xFF306998),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Looking in: $_currentScanLocation',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF306998),
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          if (_isScanning) const SizedBox(height: 16),

          // Search and Filter Section
          if (_environments.isNotEmpty || _searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Search Field
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search environments by name or path...',
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF306998)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _updateFilteredEnvironments();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filter Dropdown
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _filterType,
                      decoration: InputDecoration(
                        labelText: 'Filter by type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF306998)),
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'all', child: Text('All Types')),
                        DropdownMenuItem(value: 'conda', child: Text('Conda')),
                        DropdownMenuItem(
                            value: 'venv', child: Text('Virtual Env')),
                        DropdownMenuItem(
                            value: 'pipenv', child: Text('Pipenv')),
                        DropdownMenuItem(
                            value: 'poetry', child: Text('Poetry')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filterType = value!;
                          _updateFilteredEnvironments();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Results Count
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF306998).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: Color(0xFF306998).withOpacity(0.3)),
                    ),
                    child: Text(
                      '${_filteredEnvironments.length} / ${_environments.length}',
                      style: TextStyle(
                        color: Color(0xFF306998),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_environments.isNotEmpty || _searchQuery.isNotEmpty)
            const SizedBox(height: 16),

          // Table Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 4,
                            child: _buildHeaderText('Environment Name')),
                        Expanded(
                            flex: 2, child: _buildHeaderText('Python Version')),
                        Expanded(flex: 4, child: _buildHeaderText('Path')),
                        Expanded(flex: 2, child: _buildHeaderText('Actions')),
                      ],
                    ),
                  ),
                  // Table Content
                  Expanded(
                    child: _environments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isScanning
                                      ? Icons.search
                                      : Icons.code_outlined,
                                  size: 64,
                                  color: const Color(0xFFBDBDBD),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isScanning
                                      ? 'Scanning for Python environments...'
                                      : 'No Python environments found',
                                  style: const TextStyle(
                                    color: Color(0xFF424242),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!_isScanning) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Click "Scan Environments" to search for your Python environments',
                                    style: TextStyle(
                                      color: const Color(0xFF757575),
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : _filteredEnvironments.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: const Color(0xFFBDBDBD),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No environments match your search',
                                      style: const TextStyle(
                                        color: Color(0xFF424242),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search terms or filters',
                                      style: TextStyle(
                                        color: const Color(0xFF757575),
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredEnvironments.length,
                                itemBuilder: (context, index) {
                                  final env = _filteredEnvironments[index];
                                  return _buildEnvironmentRow(env, index);
                                },
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

  Widget _buildHeaderText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF424242),
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }

  Widget _buildEnvironmentRow(PythonEnvironment env, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.transparent : const Color(0xFFF8F9FA),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Environment Name
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getEnvironmentColor(env.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getEnvironmentIcon(env.type),
                    size: 16,
                    color: _getEnvironmentColor(env.type),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    env.name,
                    style: const TextStyle(
                      color: Color(0xFF1F2937),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Python Version
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF306998).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: const Color(0xFF306998).withOpacity(0.3)),
              ),
              child: Text(
                env.pythonVersion,
                style: const TextStyle(
                  color: Color(0xFF306998),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Path
          Expanded(
            flex: 4,
            child: Tooltip(
              message: env.path,
              child: Text(
                env.path,
                style: const TextStyle(
                  color: Color(0xFF424242),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Activate Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _activateEnvironment(env),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      minimumSize: const Size(0, 28),
                      textStyle: const TextStyle(fontSize: 10),
                    ),
                    child: const Text('Activate'),
                  ),
                ),
                const SizedBox(width: 4),
                // Open Folder Button
                IconButton(
                  onPressed: () => _openFolderLocation(env),
                  icon: const Icon(Icons.folder_open, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  tooltip: 'Open Folder',
                  color: Colors.purple[600],
                ),
                // Edit Name Button
                IconButton(
                  onPressed: () => _editEnvironmentName(env),
                  icon: const Icon(Icons.edit, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  tooltip: 'Edit Name',
                ),
                // More Options Button
                IconButton(
                  onPressed: () => _showEnvironmentDetails(env),
                  icon: const Icon(Icons.more_vert, size: 16),
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                  padding: EdgeInsets.zero,
                  splashRadius: 12,
                  tooltip: 'More Options',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEnvironmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'conda':
        return const Color(0xFF44A047);
      case 'venv':
      case 'virtualenv':
        return const Color(0xFF306998);
      case 'pipenv':
        return const Color(0xFFFFD43B);
      case 'poetry':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getEnvironmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'conda':
        return Icons.science;
      case 'venv':
      case 'virtualenv':
        return Icons.folder;
      case 'pipenv':
        return Icons.build_circle;
      case 'poetry':
        return Icons.auto_awesome;
      default:
        return Icons.code;
    }
  }
}

class ScanOptionsDialog extends StatefulWidget {
  @override
  _ScanOptionsDialogState createState() => _ScanOptionsDialogState();
}

class _ScanOptionsDialogState extends State<ScanOptionsDialog> {
  String _selectedScanType = 'full';
  List<String> _customPaths = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 640,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF306998), Color(0xFF4B79A1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Environments',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Choose where to look for Python environments',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full scan option card
                  _OptionCard(
                    selected: _selectedScanType == 'full',
                    onTap: () => setState(() => _selectedScanType = 'full'),
                    leading:
                        const Icon(Icons.computer, color: Color(0xFF306998)),
                    title: 'Scan all local drives',
                    badge: 'Recommended',
                    description:
                        'Searches all local drives (C:, D:, etc.) for Python environments. This may take several minutes.',
                  ),
                  const SizedBox(height: 12),

                  // Custom paths option card
                  _OptionCard(
                    selected: _selectedScanType == 'custom',
                    onTap: () => setState(() => _selectedScanType = 'custom'),
                    leading: const Icon(Icons.folder_special,
                        color: Color(0xFF306998)),
                    title: 'Scan specific locations',
                    description:
                        'Choose folders or drives you want to include in the scan.',
                    trailing: _selectedScanType == 'custom'
                        ? TextButton.icon(
                            onPressed: _addCustomPath,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Path'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF306998),
                              backgroundColor:
                                  const Color(0xFF306998).withOpacity(0.08),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          )
                        : null,
                  ),

                  if (_selectedScanType == 'custom') ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: _customPaths.isEmpty
                          ? Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey[600], size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No locations selected yet. Click "Add Path" to choose folders or drives.',
                                    style: TextStyle(
                                        color: Colors.grey[700], fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: _addCommonPaths,
                                  icon:
                                      const Icon(Icons.auto_awesome, size: 16),
                                  label: const Text('Add Common Locations'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF306998),
                                    backgroundColor: const Color(0xFF306998)
                                        .withOpacity(0.08),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: _addCommonPaths,
                                        icon: const Icon(Icons.auto_awesome,
                                            size: 16),
                                        label:
                                            const Text('Add Common Locations'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFF306998),
                                          backgroundColor:
                                              const Color(0xFF306998)
                                                  .withOpacity(0.08),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 6),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                    for (final p in _customPaths)
                                      Chip(
                                        avatar: const Icon(Icons.folder,
                                            size: 16, color: Color(0xFF306998)),
                                        label: Text(
                                          p,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace'),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        backgroundColor: const Color(0xFF306998)
                                            .withOpacity(0.08),
                                        deleteIcon:
                                            const Icon(Icons.close, size: 16),
                                        onDeleted: () {
                                          setState(
                                              () => _customPaths.remove(p));
                                        },
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline,
                            color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'The scanner looks for activation scripts like:\n• .venv\\Scripts\\activate.ps1\n• venv\\Scripts\\activate.bat\n• conda\\Scripts\\activate',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF1D4ED8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Footer actions
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _canStartScan()
                        ? () {
                            Navigator.of(context).pop({
                              'scanType': _selectedScanType,
                              'customPaths': _customPaths,
                            });
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF306998),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Start Scan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canStartScan() {
    if (_selectedScanType == 'full') return true;
    if (_selectedScanType == 'custom') return _customPaths.isNotEmpty;
    return false;
  }

  Future<void> _addCustomPath() async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select folder to scan for Python environments',
    );

    if (result != null && !_customPaths.contains(result)) {
      setState(() {
        _customPaths.add(result);
      });
    }
  }

  void _addCommonPaths() {
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final candidates = [
      if (userProfile.isNotEmpty) '$userProfile\\anaconda3',
      if (userProfile.isNotEmpty) '$userProfile\\miniconda3',
      if (userProfile.isNotEmpty) '$userProfile\\Documents',
      if (userProfile.isNotEmpty) '$userProfile\\Desktop',
      'C:\\Projects',
      'D:\\Projects',
      'C:\\Development',
      'D:\\Development',
      'C:\\Code',
      'D:\\Code',
    ];
    final toAdd = candidates.where((p) => !_customPaths.contains(p)).toList();
    if (toAdd.isEmpty) return;
    setState(() {
      _customPaths.addAll(toAdd);
    });
  }
}

class _OptionCard extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String? description;
  final String? badge;
  final Widget? trailing;

  const _OptionCard({
    Key? key,
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    this.description,
    this.badge,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final baseBorder = Border.all(color: const Color(0xFFE5E7EB));
    final selectedBorder =
        Border.all(color: const Color(0xFF306998), width: 1.5);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF306998).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: selected ? selectedBorder : baseBorder,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF306998).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: leading,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                                color:
                                    const Color(0xFF10B981).withOpacity(0.4)),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF065F46),
                            ),
                          ),
                        ),
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap?.call(),
              activeColor: const Color(0xFF306998),
            ),
          ],
        ),
      ),
    );
  }
}
