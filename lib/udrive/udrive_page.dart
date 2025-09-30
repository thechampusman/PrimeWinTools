import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';
import '../services/app_service_manager.dart';

class UDrivePage extends StatefulWidget {
  const UDrivePage({Key? key}) : super(key: key);

  @override
  State<UDrivePage> createState() => _UDrivePageState();
}

class _UDrivePageState extends State<UDrivePage> {
  late final AppServiceManager _serviceManager;
  bool _isServerRunning = false;
  String _serverStatus = 'Stopped';
  String _serverUrl = '';
  String _networkUrl = '';
  int _serverPort = 8080;
  String _storagePath = '';
  bool _isLoading = false;
  Timer? _statsTimer;
  Timer? _uptimeTimer;
  DateTime? _serverStartTime;
  int _localUptime = 0;
  Map<String, dynamic> _serverStats = {
    'totalFiles': 0,
    'storageUsed': 0,
    'activeConnections': 0,
    'uptime': 0,
  };

  @override
  void initState() {
    super.initState();
    _serviceManager = AppServiceManager();
    _loadSettings();
    _updateServerStatus();
  }

  Future<void> _loadSettings() async {
    try {
      // Try to load settings from a simple config file
      final configPath = path.join(
          Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'] ??
              '',
          'Documents',
          'PrimeWinTools',
          'udrive_config.json');

      final configFile = File(configPath);
      if (configFile.existsSync()) {
        final configContent = await configFile.readAsString();
        final config = jsonDecode(configContent);

        setState(() {
          _serverPort = config['port'] ?? 8080;
          _storagePath = config['storagePath'] ?? _getDefaultStoragePath();
          _serverUrl = 'http://localhost:$_serverPort';
        });
      } else {
        _initializeUDrive();
      }

      // Ensure storage directory exists
      await Directory(_storagePath).create(recursive: true);
    } catch (e) {
      print('Error loading UDrive settings: $e');
      _initializeUDrive();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final configPath = path.join(
          Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'] ??
              '',
          'Documents',
          'PrimeWinTools',
          'udrive_config.json');

      final configDir = Directory(path.dirname(configPath));
      await configDir.create(recursive: true);

      final config = {
        'port': _serverPort,
        'storagePath': _storagePath,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      final configFile = File(configPath);
      await configFile.writeAsString(jsonEncode(config));
    } catch (e) {
      print('Error saving UDrive settings: $e');
    }
  }

  String _getDefaultStoragePath() {
    final documentsPath =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    return documentsPath != null
        ? path.join(documentsPath, 'Documents', 'UDrive')
        : 'UDrive';
  }

  void _initializeUDrive() async {
    final documentsPath =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
    if (documentsPath != null) {
      _storagePath = path.join(documentsPath, 'Documents', 'UDrive');
      await Directory(_storagePath).create(recursive: true);
    }

    _serverUrl = 'http://localhost:$_serverPort';
    setState(() {});
  }

  void _updateServerStatus() {
    if (mounted) {
      setState(() {
        _isServerRunning = _serviceManager.isUDriveRunning;
        _serverStatus = _isServerRunning ? 'Running' : 'Stopped';
      });
    }
  }

  Future<void> _startServer() async {
    if (_isServerRunning) return;

    setState(() {
      _isLoading = true;
      _serverStatus = 'Starting...';
    });

    try {
      final success = await _serviceManager.startUDriveServer(
        customStoragePath: _storagePath,
        port: _serverPort,
        enableNetworkAccess: true, // Enable network access for local network
      );

      if (success) {
        // Get the actual URLs from the service manager
        final localUrl =
            _serviceManager.udriveServerUrl ?? 'http://localhost:$_serverPort';
        final networkUrl = _serviceManager.udriveNetworkUrl ?? '';

        setState(() {
          _isServerRunning = true;
          _serverStatus = 'Running';
          _isLoading = false;
          _serverUrl = localUrl;
          _networkUrl = networkUrl;
        });

        _showNotification('UDrive server started successfully!', Colors.green);
        _startStatsTimer(); // Start real-time statistics updates
        _startUptimeTimer(); // Start real-time uptime counter
      } else {
        setState(() {
          _isServerRunning = false;
          _serverStatus = 'Failed to start';
          _isLoading = false;
        });

        _showNotification('Failed to start UDrive server', Colors.red);
      }
    } catch (e) {
      setState(() {
        _isServerRunning = false;
        _serverStatus = 'Error: ${e.toString()}';
        _isLoading = false;
      });

      _showNotification(
          'Failed to start UDrive server: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _stopServer() async {
    if (!_isServerRunning) return;

    setState(() {
      _isLoading = true;
      _serverStatus = 'Stopping...';
    });

    try {
      // Only stop if user explicitly requests it, not on navigation
      await _serviceManager.stopUDriveServer(force: true);

      setState(() {
        _isServerRunning = false;
        _serverStatus = 'Stopped';
        _isLoading = false;
        _serverUrl = '';
        _networkUrl = '';
      });

      _stopStatsTimer(); // Stop statistics updates
      _stopUptimeTimer(); // Stop uptime counter
      _showNotification('UDrive server stopped', Colors.orange);
    } catch (e) {
      _showNotification('Error stopping server: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _openWebInterface() async {
    if (!_isServerRunning) {
      _showNotification('Please start the server first', Colors.orange);
      return;
    }

    try {
      // Try to open with default browser
      Process.run('rundll32', ['url.dll,FileProtocolHandler', _serverUrl]);
    } catch (e) {
      _copyUrlToClipboard();
    }
  }

  void _copyUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: _serverUrl));
    _showNotification('Server URL copied to clipboard', Colors.blue);
  }

  void _copyLocalUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: _serverUrl));
    _showNotification('Local URL copied to clipboard', Colors.blue);
  }

  void _copyNetworkUrlToClipboard() {
    Clipboard.setData(ClipboardData(text: _networkUrl));
    _showNotification(
        'Network URL copied to clipboard - share this with devices on your local network!',
        Colors.green);
  }

  void _showNotification(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _selectStoragePath() async {
    final controller = TextEditingController(text: _storagePath);

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade50,
                Colors.white,
                Colors.teal.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder,
                      color: Colors.green.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Storage Path',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Choose where UDrive stores your files',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  maxLines: 2,
                  minLines: 1,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Storage Directory Path',
                    hintText: 'Enter full path to storage folder',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon:
                        Icon(Icons.folder_open, color: Colors.green.shade600),
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Actions:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            // Use file picker to select a directory
                            String? selectedDirectory =
                                await FilePicker.platform.getDirectoryPath(
                              dialogTitle: 'Select Storage Folder',
                              initialDirectory: controller.text.isNotEmpty
                                  ? controller.text
                                  : _storagePath,
                            );

                            if (selectedDirectory != null) {
                              controller.text = selectedDirectory;
                              _showNotification(
                                  'Folder selected: ${path.basename(selectedDirectory)}',
                                  Colors.green);
                            }
                          } catch (e) {
                            _showNotification(
                                'Could not open folder picker: ${e.toString()}',
                                Colors.red);
                          }
                        },
                        icon: const Icon(Icons.folder_outlined, size: 18),
                        label: const Text('Browse Folder',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final documentsPath =
                              Platform.environment['USERPROFILE'] ??
                                  Platform.environment['HOME'];
                          if (documentsPath != null) {
                            controller.text =
                                path.join(documentsPath, 'Documents', 'UDrive');
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Use Default',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade600],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final currentPath = controller.text.isNotEmpty
                            ? controller.text
                            : _storagePath;
                        await Process.run('explorer', [currentPath]);
                        _showNotification(
                            'Opened current folder in Explorer', Colors.orange);
                      } catch (e) {
                        _showNotification(
                            'Could not open Explorer: ${e.toString()}',
                            Colors.red);
                      }
                    },
                    icon: const Icon(Icons.launch, size: 18),
                    label: const Text('Open in Explorer',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.cyan.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Use "Browse Folder" to easily select any directory, or manually type/paste a path',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.cyan.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Set Path',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _storagePath = result;
        _serverUrl = 'http://localhost:$_serverPort'; // Update URL if needed
      });

      try {
        await Directory(_storagePath).create(recursive: true);
        await _saveSettings(); // Save settings
        _showNotification('Storage path updated', Colors.green);
      } catch (e) {
        _showNotification('Invalid storage path: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _selectPort() async {
    if (_isServerRunning) {
      _showNotification(
          'Please stop the server before changing the port', Colors.orange);
      return;
    }

    final controller = TextEditingController(text: _serverPort.toString());

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.white,
                Colors.indigo.shade50,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings_ethernet,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configure Server Port',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        Text(
                          'Set the network port for UDrive server',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(5),
                  ],
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    labelText: 'Port Number',
                    hintText: 'Enter port (1024-65535)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon:
                        Icon(Icons.computer, color: Colors.blue.shade600),
                    labelStyle: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Quick Select:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final port in [3000, 5000, 8000, 8080, 9000])
                    GestureDetector(
                      onTap: () => controller.text = port.toString(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: port == _serverPort
                              ? LinearGradient(
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.blue.shade600
                                  ],
                                )
                              : LinearGradient(
                                  colors: [
                                    Colors.grey.shade100,
                                    Colors.grey.shade200
                                  ],
                                ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          port.toString(),
                          style: TextStyle(
                            color: port == _serverPort
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.amber.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ensure the port is not used by other applications',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, controller.text),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Set Port',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      final newPort = int.tryParse(result);

      if (newPort == null || newPort < 1024 || newPort > 65535) {
        _showNotification(
            'Invalid port number. Please use a port between 1024 and 65535',
            Colors.red);
        return;
      }

      setState(() {
        _serverPort = newPort;
        _serverUrl = 'http://localhost:$_serverPort';
      });

      await _saveSettings(); // Save settings
      _showNotification('Port updated to $_serverPort', Colors.green);
    }
  }

  Future<void> _resetToDefaults() async {
    if (_isServerRunning) {
      _showNotification(
          'Please stop the server before resetting to defaults', Colors.orange);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
            'This will reset the port to 8080 and storage path to the default Documents/UDrive folder. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final documentsPath =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (documentsPath != null) {
        setState(() {
          _serverPort = 8080;
          _storagePath = path.join(documentsPath, 'Documents', 'UDrive');
          _serverUrl = 'http://localhost:$_serverPort';
        });

        try {
          await Directory(_storagePath).create(recursive: true);
          await _saveSettings(); // Save settings
          _showNotification('Settings reset to defaults', Colors.green);
        } catch (e) {
          _showNotification(
              'Error creating default storage folder: ${e.toString()}',
              Colors.red);
        }
      }
    }
  }

  Future<void> _checkPortAvailability() async {
    try {
      // Try to bind to the port to check if it's available
      final serverSocket =
          await ServerSocket.bind(InternetAddress.anyIPv4, _serverPort);
      await serverSocket.close();

      _showNotification('Port $_serverPort is available! ✅', Colors.green);
    } catch (e) {
      if (e.toString().contains('Address already in use')) {
        _showNotification(
            'Port $_serverPort is already in use by another application ❌',
            Colors.red);

        // Suggest alternative ports
        _suggestAlternativePorts();
      } else {
        _showNotification(
            'Error checking port: ${e.toString()}', Colors.orange);
      }
    }
  }

  Future<void> _suggestAlternativePorts() async {
    final commonPorts = [8080, 3000, 5000, 8000, 9000, 8888, 7000, 8090];
    final availablePorts = <int>[];

    for (final port in commonPorts) {
      if (port == _serverPort) continue;

      try {
        final serverSocket =
            await ServerSocket.bind(InternetAddress.anyIPv4, port);
        await serverSocket.close();
        availablePorts.add(port);

        if (availablePorts.length >= 3) break; // Only suggest first 3 available
      } catch (e) {
        // Port is not available, continue
      }
    }

    if (availablePorts.isNotEmpty) {
      final result = await showDialog<int>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Alternative Ports Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Port $_serverPort is in use. Try one of these available ports:'),
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                children: availablePorts
                    .map((port) => ActionChip(
                          label: Text(port.toString()),
                          onPressed: () => Navigator.pop(context, port),
                          backgroundColor: Colors.green.withOpacity(0.1),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (result != null) {
        setState(() {
          _serverPort = result;
          _serverUrl = 'http://localhost:$_serverPort';
        });

        await _saveSettings();
        _showNotification('Port changed to $result', Colors.green);
      }
    }
  }

  Future<void> _fetchRealServerStats() async {
    if (!_isServerRunning) return;

    try {
      // Make HTTP request to server's info endpoint
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('$_serverUrl/api/info'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final serverInfo = jsonDecode(responseBody);

        if (serverInfo['success'] == true && serverInfo['stats'] != null) {
          setState(() {
            _serverStats = {
              'totalFiles': serverInfo['stats']['totalFiles'] ?? 0,
              'storageUsed': serverInfo['stats']['storageUsed'] ?? 0,
              'activeConnections':
                  serverInfo['stats']['activeConnections'] ?? 0,
              'uptime': serverInfo['server']['uptime'] ?? 0,
            };
          });
        }
      }
      client.close();
    } catch (e) {
      print('Error fetching server stats: $e');
      // Keep existing stats if fetch fails
    }
  }

  void _startStatsTimer() {
    _stopStatsTimer(); // Stop any existing timer

    // Update stats immediately, then every 30 minutes (reduced frequency)
    _fetchRealServerStats();
    _statsTimer = Timer.periodic(const Duration(minutes: 30), (timer) {
      _fetchRealServerStats();
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void _startUptimeTimer() {
    _stopUptimeTimer(); // Stop any existing timer
    _serverStartTime = DateTime.now();
    _localUptime = 0;

    // Update uptime every second for real-time display
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _isServerRunning) {
        setState(() {
          _localUptime = DateTime.now().difference(_serverStartTime!).inSeconds;
        });
      }
    });
  }

  void _stopUptimeTimer() {
    _uptimeTimer?.cancel();
    _uptimeTimer = null;
    _serverStartTime = null;
    _localUptime = 0;
  }

  String _formatUptime(int seconds) {
    if (seconds == 0) return 'Just started';

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.purple.withOpacity(0.1),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildServerControls(),
              const SizedBox(height: 30),
              _buildServerInfo(),
              const SizedBox(height: 30),
              _buildQuickActions(),
              const SizedBox(height: 30),
              _buildServerStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blue, Colors.purple],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.cloud,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'UDrive',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Personal Cloud Storage & Media Server',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isServerRunning ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _serverStatus,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Control',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : (_isServerRunning ? _stopServer : _startServer),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                  label:
                      Text(_isServerRunning ? 'Stop Server' : 'Start Server'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isServerRunning ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isServerRunning ? _openWebInterface : null,
                  icon: const Icon(Icons.web),
                  label: const Text('Open Web UI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServerInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Local URL', _serverUrl, Icons.computer,
              onTap: _copyLocalUrlToClipboard,
              tooltip: 'Click to copy local URL to clipboard',
              showEditIcon: false),
          if (_networkUrl.isNotEmpty)
            _buildInfoRow('Network URL', _networkUrl, Icons.wifi,
                onTap: _copyNetworkUrlToClipboard,
                tooltip:
                    'Click to copy network URL to clipboard - share this with devices on your local network',
                showEditIcon: false),
          _buildInfoRow('Port', _serverPort.toString(), Icons.settings_ethernet,
              onTap: _selectPort,
              tooltip: 'Click to change server port (requires server restart)'),
          _buildInfoRow('Storage Path', _storagePath, Icons.folder,
              onTap: _selectStoragePath,
              tooltip: 'Click to change where UDrive stores files'),
          _buildInfoRow('Status', _serverStatus, Icons.info,
              color: _isServerRunning ? Colors.green : Colors.red),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {VoidCallback? onTap,
      Color? color,
      String? tooltip,
      bool showEditIcon = true}) {
    final rowContent = GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey[600]),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? Colors.grey[700],
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onTap != null && showEditIcon)
            GestureDetector(
              onTap: onTap,
              child: Icon(Icons.edit, size: 16, color: Colors.black),
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: tooltip != null && onTap != null
          ? Tooltip(
              message: tooltip,
              child: rowContent,
            )
          : rowContent,
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildActionButton('Open Storage Folder', Icons.folder_open, () {
                Process.run('explorer', [_storagePath]);
              }),
              _buildActionButton(
                  'Copy Server URL', Icons.copy, _copyUrlToClipboard),
              _buildActionButton('Change Storage Path', Icons.edit_location,
                  () {
                _selectStoragePath();
              }),
              _buildActionButton('Change Port', Icons.settings_ethernet, () {
                _selectPort();
              }),
              _buildActionButton('Reset to Defaults', Icons.restore, () {
                _resetToDefaults();
              }),
              _buildActionButton('Check Port Availability', Icons.network_check,
                  () {
                _checkPortAvailability();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.withOpacity(0.1),
        foregroundColor: Colors.blue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildServerStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Server Statistics',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildStatCard(
                  'Total Files',
                  _serverStats['totalFiles'].toString(),
                  Icons.folder,
                  Colors.blue),
              _buildStatCard(
                  'Storage Used',
                  _formatFileSize(_serverStats['storageUsed']),
                  Icons.storage,
                  Colors.green),
              _buildStatCard(
                  'Active Connections',
                  _serverStats['activeConnections'].toString(),
                  Icons.people,
                  Colors.orange),
              _buildStatCard(
                  'Server Uptime',
                  _isServerRunning ? _formatUptime(_localUptime) : 'Inactive',
                  Icons.timer,
                  Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Stop statistics timer but keep server running for persistence across navigation
    _stopStatsTimer();
    _stopUptimeTimer();
    super.dispose();
  }
}
