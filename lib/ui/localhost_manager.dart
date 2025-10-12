import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';

class LocalhostManager extends StatefulWidget {
  const LocalhostManager({super.key});

  @override
  State<LocalhostManager> createState() => _LocalhostManagerState();
}

class _LocalhostManagerState extends State<LocalhostManager> {
  List<PortInfo> _usedPorts = [];
  bool _isScanning = false;
  String? _localIPv4;

  @override
  void initState() {
    super.initState();
    _detectLocalIp();
    _scanPorts();
  }

  Future<void> _detectLocalIp() async {
    try {
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() {
              _localIPv4 = addr.address;
            });
            return;
          }
        }
      }
    } catch (e) {
      // ignore, leave _localIPv4 null
    }
  }

  Future<void> _scanPorts() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _usedPorts.clear();
    });

    List<PortInfo> foundPorts = [];

    try {
      final result = await Process.run('netstat', ['-ano']);
      final lines = result.stdout.toString().split('\n');

      Set<int> scannedPorts = {};

      for (String line in lines) {
        if (line.contains('LISTENING') && line.contains('127.0.0.1:')) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 5) {
            try {
              final localAddress = parts[1];
              final portMatch =
                  RegExp(r'127\.0\.0\.1:(\d+)').firstMatch(localAddress);
              if (portMatch != null) {
                final port = int.parse(portMatch.group(1)!);
                final pid = parts[4];

                if (!scannedPorts.contains(port)) {
                  scannedPorts.add(port);
                  final processName = await _getProcessNameFromPid(pid);
                  final serviceInfo = _getServiceInfo(port);
                  final runType = _getRunType(processName, pid);

                  foundPorts.add(PortInfo(
                    port: port,
                    status: 'Listening',
                    protocol: 'TCP',
                    process: processName,
                    pid: pid,
                    service: serviceInfo,
                    runType: runType,
                  ));
                }
              }
            } catch (e) {}
          }
        }
      }

      final result2 = await Process.run('netstat', ['-ano']);
      final lines2 = result2.stdout.toString().split('\n');

      for (String line in lines2) {
        if (line.contains('LISTENING') &&
            (line.contains('0.0.0.0:') || line.contains('[::]:'))) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 5) {
            try {
              final localAddress = parts[1];
              int? port;

              var portMatch =
                  RegExp(r'0\.0\.0\.0:(\d+)').firstMatch(localAddress);
              if (portMatch != null) {
                port = int.parse(portMatch.group(1)!);
              } else {
                portMatch = RegExp(r'\[::\]:(\d+)').firstMatch(localAddress);
                if (portMatch != null) {
                  port = int.parse(portMatch.group(1)!);
                }
              }

              if (port != null && !scannedPorts.contains(port)) {
                try {
                  final socket = await Socket.connect('localhost', port,
                      timeout: Duration(milliseconds: 500));
                  socket.destroy();

                  scannedPorts.add(port);
                  final pid = parts[4];
                  final processName = await _getProcessNameFromPid(pid);
                  final serviceInfo = _getServiceInfo(port);
                  final runType = _getRunType(processName, pid);

                  foundPorts.add(PortInfo(
                    port: port,
                    status: 'Listening',
                    protocol: 'TCP',
                    process: processName,
                    pid: pid,
                    service: serviceInfo,
                    runType: runType,
                  ));
                } catch (e) {}
              }
            } catch (e) {}
          }
        }
      }
    } catch (e) {
      print('Error scanning ports: $e');
    }

    foundPorts.sort((a, b) {
      if (a.runType != b.runType) {
        return a.runType == 'User' ? -1 : 1;
      }
      return a.port.compareTo(b.port);
    });

    setState(() {
      _usedPorts = foundPorts;
      _isScanning = false;
    });
  }

  Future<String> _getProcessNameFromPid(String pid) async {
    try {
      final taskResult = await Process.run(
          'tasklist', ['/FI', 'PID eq $pid', '/FO', 'CSV', '/NH']);
      final taskLines = taskResult.stdout.toString().split('\n');
      if (taskLines.isNotEmpty && taskLines[0].isNotEmpty) {
        final processInfo = taskLines[0].split(',');
        if (processInfo.isNotEmpty) {
          return processInfo[0].replaceAll('"', '');
        }
      }
    } catch (e) {}
    return 'PID: $pid';
  }

  String _getRunType(String processName, String pid) {
    final systemProcesses = [
      'System',
      'svchost.exe',
      'services.exe',
      'winlogon.exe',
      'csrss.exe',
      'lsass.exe',
      'spoolsv.exe',
      'explorer.exe',
      'dwm.exe',
      'audiodg.exe',
      'conhost.exe',
      'dllhost.exe',
      'rundll32.exe',
      'taskhost.exe',
      'taskhostw.exe',
      'RuntimeBroker.exe',
      'ApplicationFrameHost.exe',
      'SearchIndexer.exe',
      'WmiPrvSE.exe',
      'MsMpEng.exe',
      'NisSrv.exe',
    ];

    final processLower = processName.toLowerCase();

    if (systemProcesses
        .any((sysProc) => processLower.contains(sysProc.toLowerCase()))) {
      return 'System';
    }

    if (processLower.contains('node') ||
        processLower.contains('npm') ||
        processLower.contains('yarn') ||
        processLower.contains('python') ||
        processLower.contains('java') ||
        processLower.contains('dotnet') ||
        processLower.contains('code') ||
        processLower.contains('chrome') ||
        processLower.contains('firefox') ||
        processLower.contains('iisexpress')) {
      return 'User';
    }

    return 'User';
  }

  String _getServiceInfo(int port) {
    final commonServices = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      143: 'IMAP',
      443: 'HTTPS',
      993: 'IMAPS',
      995: 'POP3S',
      1433: 'SQL Server',
      3000: 'Node.js Dev',
      3001: 'React Dev',
      4200: 'Angular Dev',
      5000: 'Flask/ASP.NET',
      5001: 'ASP.NET HTTPS',
      5173: 'Vite Dev',
      5432: 'PostgreSQL',
      5672: 'RabbitMQ',
      6379: 'Redis',
      8000: 'Python Dev',
      8080: 'HTTP Alt',
      8081: 'HTTP Alt 2',
      8888: 'Jupyter',
      9000: 'SonarQube',
      9090: 'Prometheus',
      27017: 'MongoDB',
    };

    return commonServices[port] ?? 'Custom Service';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localhost Manager',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A1A1A),
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monitor active localhost ports and services',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF666666),
                          ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _scanPorts,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    _isScanning ? 'Scanning...' : 'Refresh',
                    style: const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Active Ports',
                    _usedPorts.length.toString(),
                    Icons.router,
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'User Services',
                    _usedPorts
                        .where((p) => p.runType == 'User')
                        .length
                        .toString(),
                    Icons.person,
                    const Color(0xFF2196F3),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'System Services',
                    _usedPorts
                        .where((p) => p.runType == 'System')
                        .length
                        .toString(),
                    Icons.settings,
                    const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
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
                          Expanded(flex: 2, child: _buildHeaderText('Port')),
                          Expanded(flex: 2, child: _buildHeaderText('Service')),
                          Expanded(
                              flex: 2, child: _buildHeaderText('Run Type')),
                          Expanded(flex: 3, child: _buildHeaderText('Process')),
                          Expanded(flex: 2, child: _buildHeaderText('PID')),
                          Expanded(flex: 2, child: _buildHeaderText('Actions')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _usedPorts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isScanning
                                        ? Icons.search
                                        : Icons.router_outlined,
                                    size: 64,
                                    color: const Color(0xFFBDBDBD),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isScanning
                                        ? 'Scanning ports...'
                                        : 'No active ports found',
                                    style: const TextStyle(
                                      color: Color(0xFF424242),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (!_isScanning) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Click refresh to scan for active localhost services',
                                      style: TextStyle(
                                        color: const Color(0xFF757575),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _usedPorts.length,
                              itemBuilder: (context, index) {
                                final port = _usedPorts[index];
                                return _buildPortRow(port, index);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
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

  Widget _buildPortRow(PortInfo port, int index) {
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
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: const Color(0xFF1976D2).withOpacity(0.3)),
                  ),
                  child: Text(
                    ':${port.port}',
                    style: const TextStyle(
                      color: Color(0xFF1976D2),
                      fontFamily: 'monospace',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                if (_localIPv4 != null)
                  Tooltip(
                    message: 'Open network URL: http://${_localIPv4}:${port.port}',
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _openNetworkUrl(port.port),
                        child: Text(
                          'http://${_localIPv4}:${port.port}',
                          style: const TextStyle(
                            color: Color(0xFF1976D2),
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    'No LAN IP',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getServiceColor(port.service).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _getServiceColor(port.service).withOpacity(0.3)),
              ),
              child: Text(
                port.service,
                style: TextStyle(
                  color: _getServiceColor(port.service),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRunTypeColor(port.runType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: _getRunTypeColor(port.runType).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    port.runType == 'User' ? Icons.person : Icons.settings,
                    size: 12,
                    color: _getRunTypeColor(port.runType),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    port.runType,
                    style: TextStyle(
                      color: _getRunTypeColor(port.runType),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              port.process,
              style: const TextStyle(
                color: Color(0xFF424242),
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                port.pid,
                style: const TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _openInBrowser(port.port),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  tooltip: 'Open in browser',
                  color: const Color(0xFF2196F3),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () => _copyToClipboard('localhost:${port.port}'),
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy URL',
                  color: const Color(0xFF757575),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF757575).withOpacity(0.1),
                    minimumSize: const Size(32, 32),
                  ),
                ),
                const SizedBox(width: 4),
                if (_localIPv4 != null)
                  IconButton(
                    onPressed: () => _copyNetworkUrl(port.port),
                    icon: const Icon(Icons.share, size: 18),
                    tooltip: 'Copy network URL',
                    color: const Color(0xFF757575),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF757575).withOpacity(0.1),
                      minimumSize: const Size(32, 32),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRunTypeColor(String runType) {
    switch (runType) {
      case 'User':
        return const Color(0xFF4CAF50);
      case 'System':
        return const Color(0xFF9E9E9E);
      default:
        return const Color(0xFF2196F3);
    }
  }

  Color _getServiceColor(String service) {
    switch (service) {
      case 'HTTP':
      case 'HTTPS':
        return const Color(0xFF4CAF50);
      case 'Node.js Dev':
      case 'React Dev':
      case 'Angular Dev':
      case 'Vite Dev':
        return const Color(0xFFFF9800);
      case 'SQL Server':
      case 'PostgreSQL':
      case 'MongoDB':
        return const Color(0xFF9C27B0);
      case 'Flask/ASP.NET':
      case 'ASP.NET HTTPS':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF607D8B);
    }
  }

  void _openInBrowser(int port) async {
    try {
      await Process.start('cmd', ['/c', 'start', 'http://localhost:$port']);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open browser: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openNetworkUrl(int port) async {
    if (_localIPv4 == null) return;
    final url = 'http://${_localIPv4!}:$port';
    try {
      await Process.start('cmd', ['/c', 'start', url]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open network URL: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _copyNetworkUrl(int port) async {
    if (_localIPv4 == null) return;
    final url = 'http://${_localIPv4!}:$port';
    _copyToClipboard(url);
  }

  void _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to copy: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

class PortInfo {
  final int port;
  final String status;
  final String protocol;
  final String process;
  final String pid;
  final String service;
  final String runType;

  PortInfo({
    required this.port,
    required this.status,
    required this.protocol,
    required this.process,
    required this.pid,
    required this.service,
    required this.runType,
  });
}
