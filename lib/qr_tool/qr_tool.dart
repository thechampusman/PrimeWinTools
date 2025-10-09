import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class QRCodeTool extends StatefulWidget {
  const QRCodeTool({Key? key}) : super(key: key);

  @override
  State<QRCodeTool> createState() => _QRCodeToolState();
}

class _QRCodeToolState extends State<QRCodeTool> {
  String? qrToolPath;
  bool isServerRunning = false;
  HttpServer? server;
  int serverPort = 8088;

  @override
  void initState() {
    super.initState();
    _setupQRTool();
  }

  @override
  void dispose() {
    _stopServer();
    super.dispose();
  }

  void _setupQRTool() {
    qrToolPath = _getQRToolPath();
    
  }

  Future<void> _manualStartServer() async {
    await _startLocalServer();
    if (mounted) {
      setState(() {});
    }
  }

  String _getQRToolPath() {
    final appDir = Directory.current.path;
    return path.join(appDir, 'lib', 'qr_tool', 'qr_working.html');
  }

  Future<String> _getNetworkUrl() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return 'http://${addr.address}:$serverPort';
          }
        }
      }
      return 'http://localhost:$serverPort';
    } catch (e) {
      return 'http://localhost:$serverPort';
    }
  }

  Future<void> _startLocalServer() async {
    try {
      
      for (int port = 8088; port <= 8099; port++) {
        try {
          server = await HttpServer.bind('localhost', port);
          serverPort = port;
          isServerRunning = true;
          break;
        } catch (e) {
          
          continue;
        }
      }

      if (server == null) {
        _showError('Could not find an available port');
        return;
      }

      server!.listen((HttpRequest request) async {
        try {
          final file = File(qrToolPath!);
          if (await file.exists()) {
            request.response.headers.contentType = ContentType.html;
            request.response.headers.set('Access-Control-Allow-Origin', '*');
            request.response.headers
                .set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
            request.response.headers
                .set('Access-Control-Allow-Headers', 'Origin, Content-Type');

            if (request.method == 'OPTIONS') {
              request.response.statusCode = 200;
              await request.response.close();
              return;
            }

            await request.response.addStream(file.openRead());
            await request.response.close();
          } else {
            request.response.statusCode = 404;
            request.response.write('QR Tool not found');
            await request.response.close();
          }
        } catch (e) {
          request.response.statusCode = 500;
          request.response.write('Server error: $e');
          await request.response.close();
        }
      });

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _showError('Failed to start server: $e');
    }
  }

  void _stopServer() {
    server?.close();
    server = null;
    isServerRunning = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openInBrowser() async {
    if (!isServerRunning) return;

    try {
      final url = 'http://localhost:$serverPort';

      if (Platform.isWindows) {
        await Process.start('cmd', ['/c', 'start', url], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.start('open', [url]);
      } else if (Platform.isLinux) {
        await Process.start('xdg-open', [url]);
      } else {
        _showError('Unsupported platform');
      }
    } catch (e) {
      _showError('Failed to open browser: $e');
    }
  }

  Future<void> _copyUrl() async {
    if (!isServerRunning) return;

    final url = 'http://localhost:$serverPort';
    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Local URL copied to clipboard'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _copyNetworkUrl() async {
    if (!isServerRunning) return;

    final url = await _getNetworkUrl();
    await Clipboard.setData(ClipboardData(text: url));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network URL copied to clipboard'),
          backgroundColor: Colors.purple,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 800;
          final isVerySmallScreen = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isVerySmallScreen ? 16 : 24),
            child: Column(
              children: [
                
                Flex(
                  direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: isSmallScreen
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: isSmallScreen
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Code Tool',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 24 : 28,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: isVerySmallScreen ? 4 : 8),
                        Text(
                          'Generate and scan QR codes with advanced features',
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 14 : 16,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                    if (isSmallScreen) const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isServerRunning
                              ? _openInBrowser
                              : _manualStartServer,
                          icon: isServerRunning
                              ? const Icon(Icons.launch, color: Colors.white)
                              : const Icon(Icons.play_arrow,
                                  color: Colors.white),
                          label: Text(
                            isServerRunning ? 'Open QR Tool' : 'Start Server',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            padding: EdgeInsets.symmetric(
                                horizontal: isVerySmallScreen ? 16 : 20,
                                vertical: 12),
                          ),
                        ),
                        if (isServerRunning)
                          ElevatedButton.icon(
                            onPressed: () {
                              _stopServer();
                              setState(() {});
                            },
                            icon: const Icon(Icons.stop, color: Colors.white),
                            label: const Text('Stop Server',
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF44336),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: EdgeInsets.symmetric(
                                  horizontal: isVerySmallScreen ? 16 : 20,
                                  vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isVerySmallScreen ? 24 : 32),

                
                isSmallScreen
                    ? Column(
                        children: [
                          _buildStatCard(
                            'Server Status',
                            isServerRunning ? 'Running' : 'Stopped',
                            isServerRunning ? Icons.check_circle : Icons.error,
                            isServerRunning
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF44336),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Local Port',
                            isServerRunning ? serverPort.toString() : '---',
                            Icons.router,
                            const Color(0xFF2196F3),
                          ),
                          const SizedBox(height: 16),
                          _buildStatCard(
                            'Network Access',
                            isServerRunning ? 'Available' : 'Not Available',
                            Icons.network_check,
                            isServerRunning
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF9E9E9E),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Server Status',
                              isServerRunning ? 'Running' : 'Stopped',
                              isServerRunning
                                  ? Icons.check_circle
                                  : Icons.error,
                              isServerRunning
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFF44336),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Local Port',
                              isServerRunning ? serverPort.toString() : '---',
                              Icons.router,
                              const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Network Access',
                              isServerRunning ? 'Available' : 'Not Available',
                              Icons.network_check,
                              isServerRunning
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: isVerySmallScreen ? 24 : 32),

                
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: isSmallScreen ? double.infinity : 600,
                    ),
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        
                        Container(
                          padding: EdgeInsets.all(isVerySmallScreen ? 12 : 16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: const Color(0xFF666666), size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Server Information',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        Padding(
                          padding: EdgeInsets.all(isVerySmallScreen ? 16 : 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInfoRow('Status',
                                  isServerRunning ? 'Active' : 'Inactive'),
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              _buildInfoRow(
                                  'Local Port',
                                  isServerRunning
                                      ? serverPort.toString()
                                      : 'Not assigned'),
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              _buildInfoRow(
                                  'Local URL',
                                  isServerRunning
                                      ? 'http://localhost:$serverPort'
                                      : 'Server not running'),
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              FutureBuilder<String>(
                                future: isServerRunning
                                    ? _getNetworkUrl()
                                    : Future.value('Server not running'),
                                builder: (context, snapshot) {
                                  return _buildInfoRow('Network URL',
                                      snapshot.data ?? 'Loading...');
                                },
                              ),
                              SizedBox(height: isVerySmallScreen ? 16 : 24),
                              const Divider(),
                              SizedBox(height: isVerySmallScreen ? 12 : 16),
                              Text(
                                'QR Tool Features',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1A1A),
                                ),
                              ),
                              SizedBox(height: isVerySmallScreen ? 8 : 12),
                              ..._buildFeaturesList(isVerySmallScreen),
                              if (isServerRunning) ...[
                                SizedBox(height: isVerySmallScreen ? 12 : 16),
                                isVerySmallScreen
                                    ? Column(
                                        children: [
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () => _copyUrl(),
                                              icon: const Icon(Icons.copy),
                                              label:
                                                  const Text('Copy Local URL'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _copyNetworkUrl(),
                                              icon: const Icon(Icons.share),
                                              label: const Text(
                                                  'Copy Network URL'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF9C27B0),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _copyUrl(),
                                              icon: const Icon(Icons.copy),
                                              label:
                                                  const Text('Copy Local URL'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _copyNetworkUrl(),
                                              icon: const Icon(Icons.share),
                                              label: const Text(
                                                  'Copy Network URL'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF9C27B0),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ],
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
        },
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1A1A1A),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFeaturesList([bool isSmall = false]) {
    final features = [
      'Generate QR codes from text, URLs, emails',
      'Customizable colors and error correction',
      'Live camera QR code scanning',
      'Upload image files for QR scanning',
      'Download QR codes as PNG images',
      'Copy QR codes to clipboard',
      'Quick templates for WiFi, contacts, etc.',
    ];

    return features
        .map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: const Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: isSmall ? 11 : 12,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
            ))
        .toList();
  }
}


class QRToolIntegration {
  static const String toolName = 'QR Code Tool';
  static const String toolDescription =
      'Generate and scan QR codes with advanced options';
  static const IconData toolIcon = Icons.qr_code;
  static const Color toolColor = Colors.deepPurple;

  static Widget getToolTile() {
    return Builder(
      builder: (context) => Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QRCodeTool(),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  toolIcon,
                  size: 48,
                  color: toolColor,
                ),
                const SizedBox(height: 12),
                Text(
                  toolName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  toolDescription,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void addToMainApp() {
    
    
  }
}
