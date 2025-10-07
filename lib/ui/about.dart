import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class About extends StatefulWidget {
  const About({super.key});

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> {
  String _systemInfo = 'Loading...';
  String _flutterVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadSystemInfo();
  }

  Future<void> _loadSystemInfo() async {
    try {
      final result = await Process.run('systeminfo', []);
      final lines = result.stdout.toString().split('\n');
      String osName = 'Windows';
      String osVersion = 'Unknown';
      String totalMemory = 'Unknown';

      for (String line in lines) {
        if (line.contains('OS Name:')) {
          osName = line.split(':')[1].trim();
        }
        if (line.contains('OS Version:')) {
          osVersion = line.split(':')[1].trim();
        }
        if (line.contains('Total Physical Memory:')) {
          totalMemory = line.split(':')[1].trim();
        }
      }

      setState(() {
        _systemInfo = '$osName\n$osVersion\nRAM: $totalMemory';
        _flutterVersion = 'Flutter 3.x Framework';
      });
    } catch (e) {
      setState(() {
        _systemInfo = 'Windows ${Platform.operatingSystemVersion}';
        _flutterVersion = 'Flutter Framework';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(),
            const SizedBox(height: 32),
            _buildQuickStatsRow(),
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildSoftwareInfoCard(),
                      const SizedBox(height: 20),
                      _buildSystemInfoCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      // Developer info adds credibility and context
                      _buildDeveloperInfoCard(),
                      const SizedBox(height: 20),
                      _buildFeaturesGrid(),
                      const SizedBox(height: 20),
                      // Technical specs help users understand requirements
                      _buildTechnicalSpecsCard(),
                      const SizedBox(height: 20),
                      _buildLegalInfoCard(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.build_circle,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'PrimeWinTools',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Advanced System Optimization & Privacy Suite',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Text(
              'Version 1.1.0 • Build 2025.10.02',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('Platform', 'Windows', Icons.laptop_windows,
                const Color(0xFF2196F3))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard(
                'Framework', 'Flutter', Icons.code, const Color(0xFF9C27B0))),
        const SizedBox(width: 16),
        Expanded(
            child: _buildStatCard('License', 'Proprietary', Icons.security,
                const Color(0xFFFF9800))),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF666666),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftwareInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Software Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Application Name', 'PrimeWinTools'),
          _buildInfoRow('Version', '1.0.3'),
          _buildInfoRow('Build Date', 'September 3, 2025'),
          _buildInfoRow('Architecture', '64-bit'),
          _buildInfoRow('Framework', 'Flutter 3.x'),
          _buildInfoRow('Language', 'Dart'),
          _buildInfoRow('Platform', 'Windows 10+'),
          _buildInfoRow('License Type', 'Proprietary'),
          _buildInfoRow('Developer', 'Usman (The Champ)'),
          _buildInfoRow('Category', 'System Utilities'),
        ],
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.computer,
                  color: Color(0xFF4CAF50),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'System Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Text(
              _systemInfo,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF495057),
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Runtime', _flutterVersion),
          _buildInfoRow(
              'Architecture', Platform.isWindows ? 'Windows x64' : 'Unknown'),
          _buildInfoRow('Locale', Platform.localeName),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF9C27B0),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Developer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Name', 'Usman (The Champ)'),
          _buildInfoRow('GitHub', '@thechampusman'),
          _buildInfoRow('Email', 'usmangourworkingid@gmail.com'),
          _buildInfoRow('Location', 'Pakistan'),
          _buildInfoRow('Specialization', 'Windows Development'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '💡 Passionate about creating efficient Windows utilities that enhance user productivity and system performance.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4A148C),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Color(0xFFFF9800),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Key Features',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildFeatureCard(
                '🧹',
                'Advanced System Cleaner',
                'Clean temp files\nPrivacy traces removal\nCustomizable categories',
                const Color(0xFF4CAF50),
              ),
              _buildFeatureCard(
                '🔒',
                'Privacy Protection',
                'Remove thumbnail cache\nBrowser history cleanup\nSecure data removal',
                const Color(0xFFE91E63),
              ),
              _buildFeatureCard(
                '📋',
                'Smart Clipboard Manager',
                '20-day history\nAutomatic tracking\nQuick access overlay',
                const Color(0xFF2196F3),
              ),
              _buildFeatureCard(
                '📱',
                'QR Code Generator',
                'Responsive design\nInstant generation\nMultiple formats',
                const Color(0xFF673AB7),
              ),
              _buildFeatureCard(
                '🌐',
                'Localhost Manager',
                'Port monitoring\nService detection\nReal-time status',
                const Color(0xFF9C27B0),
              ),
              _buildFeatureCard(
                '⚙️',
                'Configurable Settings',
                'Custom clean categories\nPersonalized experience\nSafe operations',
                const Color(0xFF607D8B),
              ),
              _buildFeatureCard(
                '📊',
                'Detailed Scanning',
                'Category-based results\nExpandable file lists\nSize analytics',
                const Color(0xFFFF5722),
              ),
              _buildFeatureCard(
                '⚡',
                'High Performance',
                'Native speed\nLow memory usage\nEfficient algorithms',
                const Color(0xFFFF9800),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
      String emoji, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF607D8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF607D8B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Technical Specifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Minimum Windows Version', 'Windows 10 (1903)'),
          _buildInfoRow('Recommended RAM', '4 GB or higher'),
          _buildInfoRow('Disk Space Required', '< 100 MB'),
          _buildInfoRow('Network Requirements', 'None (offline app)'),
          _buildInfoRow('Dependencies', 'Flutter Runtime'),
          _buildInfoRow('Database', 'SQLite (local)'),
          _buildInfoRow('UI Framework', 'Material Design 3'),
          _buildInfoRow('Update Mechanism', 'Manual download'),
          _buildInfoRow('Data Storage', 'Local AppData folder'),
          _buildInfoRow('Permissions Required', 'Standard user'),
        ],
      ),
    );
  }

  Widget _buildLegalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.gavel,
                  color: Color(0xFFE91E63),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Legal Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow('Copyright', '© 2025 Usman (The Champ)'),
          _buildInfoRow('License', 'Proprietary License'),
          _buildInfoRow('Trademark', 'PrimeWinTools™'),
          _buildInfoRow('Privacy Policy', 'No data collection'),
          _buildInfoRow('Terms of Use', 'See LICENSE.txt'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFCE4EC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⚠️ Important Notice',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2185B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This software is provided "as is" without warranty. Use at your own risk. Always backup important data before running system cleanup operations.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF880E4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
          ),
          const Text(':', style: TextStyle(color: Color(0xFF666666))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
