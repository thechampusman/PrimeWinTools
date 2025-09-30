import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/qr_generator_service.dart';

class QRToolPython extends StatefulWidget {
  const QRToolPython({Key? key}) : super(key: key);

  @override
  State<QRToolPython> createState() => _QRToolPythonState();
}

class _QRToolPythonState extends State<QRToolPython>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Controllers
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _emailSubjectController = TextEditingController();
  final TextEditingController _emailBodyController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsPhoneController = TextEditingController();
  final TextEditingController _smsMessageController = TextEditingController();

  // WiFi controllers
  final TextEditingController _wifiSSIDController = TextEditingController();
  final TextEditingController _wifiPasswordController = TextEditingController();
  String _wifiSecurity = 'WPA';

  // vCard controllers
  final TextEditingController _vCardNameController = TextEditingController();
  final TextEditingController _vCardPhoneController = TextEditingController();
  final TextEditingController _vCardEmailController = TextEditingController();
  final TextEditingController _vCardOrgController = TextEditingController();
  final TextEditingController _vCardUrlController = TextEditingController();

  // QR settings
  String _contentType = 'text';
  int _qrSize = 512;
  String _errorLevel = 'M';
  String _qrStyle = 'square';
  Color _fgColor = Colors.black;
  Color _bgColor = Colors.white;

  // State
  Uint8List? _qrImageBytes;
  bool _isGenerating = false;
  String? _lastError;
  bool _pythonAvailable = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPythonAvailability();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _urlController.dispose();
    _emailController.dispose();
    _emailSubjectController.dispose();
    _emailBodyController.dispose();
    _phoneController.dispose();
    _smsPhoneController.dispose();
    _smsMessageController.dispose();
    _wifiSSIDController.dispose();
    _wifiPasswordController.dispose();
    _vCardNameController.dispose();
    _vCardPhoneController.dispose();
    _vCardEmailController.dispose();
    _vCardOrgController.dispose();
    _vCardUrlController.dispose();
    super.dispose();
  }

  Future<void> _checkPythonAvailability() async {
    final available = await QRCodeGenerator.checkAvailability();
    setState(() {
      _pythonAvailable = available;
    });

    if (available) {
      _showMessage('Python detected. Installing QR packages...', Colors.blue);
      final installed = await QRCodeGenerator.installRequirements();

      if (installed) {
        _showMessage('QR generator ready!', Colors.green);
      } else {
        _showMessage(
            'Failed to install QR packages. Some features may not work.',
            Colors.orange);
      }
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _getContentData() {
    switch (_contentType) {
      case 'text':
        return _textController.text;
      case 'url':
        return _urlController.text;
      case 'email':
        final email = _emailController.text;
        final subject = _emailSubjectController.text;
        final body = _emailBodyController.text;
        String mailto = 'mailto:$email';
        if (subject.isNotEmpty || body.isNotEmpty) {
          mailto += '?';
          if (subject.isNotEmpty)
            mailto += 'subject=${Uri.encodeComponent(subject)}';
          if (subject.isNotEmpty && body.isNotEmpty) mailto += '&';
          if (body.isNotEmpty) mailto += 'body=${Uri.encodeComponent(body)}';
        }
        return mailto;
      case 'phone':
        return 'tel:${_phoneController.text}';
      case 'sms':
        final phone = _smsPhoneController.text;
        final message = _smsMessageController.text;
        return 'sms:$phone?body=${Uri.encodeComponent(message)}';
      default:
        return _textController.text;
    }
  }

  Future<void> _generateQR() async {
    if (!_pythonAvailable) {
      _showMessage('Python is not available on this system', Colors.red);
      return;
    }

    setState(() {
      _isGenerating = true;
      _lastError = null;
    });

    try {
      QRGenerationResult result;

      if (_contentType == 'wifi') {
        result = await QRCodeGenerator.generateWifiQR(
          ssid: _wifiSSIDController.text,
          password: _wifiPasswordController.text,
          security: _wifiSecurity,
          size: _qrSize,
          style: _qrStyle,
        );
      } else if (_contentType == 'vcard') {
        result = await QRCodeGenerator.generateVCardQR(
          name: _vCardNameController.text,
          phone: _vCardPhoneController.text,
          email: _vCardEmailController.text,
          organization: _vCardOrgController.text,
          url: _vCardUrlController.text,
          size: _qrSize,
          style: _qrStyle,
        );
      } else {
        final data = _getContentData();
        if (data.isEmpty) {
          _showMessage('Please enter content to generate QR code', Colors.red);
          setState(() => _isGenerating = false);
          return;
        }

        result = await QRCodeGenerator.generateBase64(
          data: data,
          size: _qrSize,
          errorCorrection: _errorLevel,
          fgColor:
              '#${_fgColor.value.toRadixString(16).substring(2).toUpperCase()}',
          bgColor:
              '#${_bgColor.value.toRadixString(16).substring(2).toUpperCase()}',
          style: _qrStyle,
        );
      }

      if (result.success && result.imageBytes != null) {
        setState(() {
          _qrImageBytes = result.imageBytes;
        });
        _showMessage('QR code generated successfully!', Colors.green);
      } else {
        setState(() {
          _lastError = result.error ?? 'Unknown error occurred';
        });
        _showMessage(result.error ?? 'Failed to generate QR code', Colors.red);
      }
    } catch (e) {
      setState(() {
        _lastError = e.toString();
      });
      _showMessage('Error: $e', Colors.red);
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Future<void> _downloadQR() async {
    if (_qrImageBytes == null) {
      _showMessage('No QR code to download', Colors.red);
      return;
    }

    try {
      // For Windows, save to Downloads folder
      final downloadsPath = Platform.isWindows
          ? '${Platform.environment['USERPROFILE']}\\Downloads'
          : '${Platform.environment['HOME']}/Downloads';

      final fileName = 'qrcode_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '$downloadsPath\\$fileName';

      final file = File(filePath);
      await file.writeAsBytes(_qrImageBytes!);

      _showMessage('QR code saved to Downloads folder', Colors.green);
    } catch (e) {
      _showMessage('Failed to save QR code: $e', Colors.red);
    }
  }

  Future<void> _copyQR() async {
    if (_qrImageBytes != null) {
      // For now, just show a message - copying images to clipboard is complex
      _showMessage('Use Download to save the QR code', Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Generator'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Generate', icon: Icon(Icons.qr_code)),
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
            Tab(text: 'Preview', icon: Icon(Icons.preview)),
          ],
        ),
      ),
      body: !_pythonAvailable
          ? _buildPythonNotAvailableView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGenerateTab(),
                _buildSettingsTab(),
                _buildPreviewTab(),
              ],
            ),
    );
  }

  Widget _buildPythonNotAvailableView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 20),
            const Text(
              'Python Not Available',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Python is required to generate QR codes. Please install Python and restart the application.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkPythonAvailability,
              child: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content Type Selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Content Type',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _contentType,
                    onChanged: (value) => setState(() => _contentType = value!),
                    items: const [
                      DropdownMenuItem(value: 'text', child: Text('Text')),
                      DropdownMenuItem(value: 'url', child: Text('URL')),
                      DropdownMenuItem(value: 'email', child: Text('Email')),
                      DropdownMenuItem(value: 'phone', child: Text('Phone')),
                      DropdownMenuItem(value: 'sms', child: Text('SMS')),
                      DropdownMenuItem(value: 'wifi', child: Text('WiFi')),
                      DropdownMenuItem(
                          value: 'vcard', child: Text('Contact (vCard)')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Content Input
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildContentInput(),
            ),
          ),
          const SizedBox(height: 20),

          // Generate Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generateQR,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isGenerating
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Generating...'),
                      ],
                    )
                  : const Text('Generate QR Code',
                      style: TextStyle(fontSize: 18)),
            ),
          ),

          // Error Display
          if (_lastError != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _lastError!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentInput() {
    switch (_contentType) {
      case 'text':
        return TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Text Content',
            hintText: 'Enter text to encode',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        );

      case 'url':
        return TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com',
            border: OutlineInputBorder(),
          ),
        );

      case 'email':
        return Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailSubjectController,
              decoration: const InputDecoration(
                labelText: 'Subject (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailBodyController,
              decoration: const InputDecoration(
                labelText: 'Message (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        );

      case 'phone':
        return TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: '+1234567890',
            border: OutlineInputBorder(),
          ),
        );

      case 'sms':
        return Column(
          children: [
            TextField(
              controller: _smsPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: '+1234567890',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _smsMessageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        );

      case 'wifi':
        return Column(
          children: [
            TextField(
              controller: _wifiSSIDController,
              decoration: const InputDecoration(
                labelText: 'WiFi Network Name (SSID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _wifiPasswordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _wifiSecurity,
              onChanged: (value) => setState(() => _wifiSecurity = value!),
              decoration: const InputDecoration(
                labelText: 'Security Type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'WPA', child: Text('WPA/WPA2')),
                DropdownMenuItem(value: 'WEP', child: Text('WEP')),
                DropdownMenuItem(
                    value: 'nopass', child: Text('Open (No Password)')),
              ],
            ),
          ],
        );

      case 'vcard':
        return Column(
          children: [
            TextField(
              controller: _vCardNameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vCardPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vCardEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vCardOrgController,
              decoration: const InputDecoration(
                labelText: 'Organization',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vCardUrlController,
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );

      default:
        return TextField(
          controller: _textController,
          decoration: const InputDecoration(
            labelText: 'Content',
            border: OutlineInputBorder(),
          ),
        );
    }
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('QR Code Settings',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Size: $_qrSize px'),
                  Slider(
                    value: _qrSize.toDouble(),
                    min: 128,
                    max: 1024,
                    divisions: 7,
                    onChanged: (value) =>
                        setState(() => _qrSize = value.toInt()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _errorLevel,
                    onChanged: (value) => setState(() => _errorLevel = value!),
                    decoration: const InputDecoration(
                      labelText: 'Error Correction Level',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Low (~7%)')),
                      DropdownMenuItem(
                          value: 'M', child: Text('Medium (~15%)')),
                      DropdownMenuItem(
                          value: 'Q', child: Text('Quartile (~25%)')),
                      DropdownMenuItem(value: 'H', child: Text('High (~30%)')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _qrStyle,
                    onChanged: (value) => setState(() => _qrStyle = value!),
                    decoration: const InputDecoration(
                      labelText: 'Style',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'square', child: Text('Square')),
                      DropdownMenuItem(
                          value: 'rounded', child: Text('Rounded')),
                      DropdownMenuItem(value: 'circle', child: Text('Circle')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_qrImageBytes != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _qrImageBytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _downloadQR,
                          icon: const Icon(Icons.download),
                          label: const Text('Download'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _copyQR,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Card(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.qr_code, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No QR Code Generated',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Generate a QR code to see the preview',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
