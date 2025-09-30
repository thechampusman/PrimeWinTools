import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class QRCodeGenerator {
  static const String _scriptPath = 'scripts/qr_generator.py';

  /// Check if Python and required packages are available
  static Future<bool> checkAvailability() async {
    try {
      final result = await Process.run('python', ['--version']);
      if (result.exitCode != 0) {
        // Try python3
        final result3 = await Process.run('python3', ['--version']);
        return result3.exitCode == 0;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Install required Python packages
  static Future<bool> installRequirements() async {
    try {
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        print('QR generator script not found at $_scriptPath');
        return false;
      }

      final result = await Process.run(
        'python',
        [scriptFile.absolute.path, '--install'],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode != 0) {
        // Try python3
        final result3 = await Process.run(
          'python3',
          [scriptFile.absolute.path, '--install'],
          workingDirectory: Directory.current.path,
        );
        return result3.exitCode == 0;
      }

      return result.exitCode == 0;
    } catch (e) {
      print('Error installing requirements: $e');
      return false;
    }
  }

  /// Generate QR code and save to file
  static Future<QRGenerationResult> generateToFile({
    required String data,
    required String outputPath,
    int size = 512,
    int border = 4,
    String errorCorrection = 'M',
    String fgColor = 'black',
    String bgColor = 'white',
    String style = 'square',
    String format = 'PNG',
  }) async {
    try {
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        return QRGenerationResult(
          success: false,
          error: 'QR generator script not found at $_scriptPath',
        );
      }

      final args = [
        scriptFile.absolute.path,
        '--data',
        data,
        '--output',
        outputPath,
        '--size',
        size.toString(),
        '--border',
        border.toString(),
        '--error-correction',
        errorCorrection,
        '--fg-color',
        fgColor,
        '--bg-color',
        bgColor,
        '--style',
        style,
        '--format',
        format,
        '--json',
      ];

      // Try python first, then python3
      ProcessResult result;
      try {
        result = await Process.run('python', args,
            workingDirectory: Directory.current.path);
      } catch (e) {
        result = await Process.run('python3', args,
            workingDirectory: Directory.current.path);
      }

      if (result.exitCode == 0) {
        final jsonResult = jsonDecode(result.stdout as String);
        return QRGenerationResult.fromJson(jsonResult);
      } else {
        return QRGenerationResult(
          success: false,
          error: result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : result.stdout.toString(),
        );
      }
    } catch (e) {
      return QRGenerationResult(
        success: false,
        error: 'Failed to execute QR generator: $e',
      );
    }
  }

  /// Generate QR code and return as base64 string
  static Future<QRGenerationResult> generateBase64({
    required String data,
    int size = 512,
    int border = 4,
    String errorCorrection = 'M',
    String fgColor = 'black',
    String bgColor = 'white',
    String style = 'square',
    String format = 'PNG',
  }) async {
    try {
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        return QRGenerationResult(
          success: false,
          error: 'QR generator script not found at $_scriptPath',
        );
      }

      final args = [
        scriptFile.absolute.path,
        '--data',
        data,
        '--size',
        size.toString(),
        '--border',
        border.toString(),
        '--error-correction',
        errorCorrection,
        '--fg-color',
        fgColor,
        '--bg-color',
        bgColor,
        '--style',
        style,
        '--format',
        format,
        '--json',
      ];

      // Try python first, then python3
      ProcessResult result;
      try {
        result = await Process.run('python', args,
            workingDirectory: Directory.current.path);
      } catch (e) {
        result = await Process.run('python3', args,
            workingDirectory: Directory.current.path);
      }

      if (result.exitCode == 0) {
        final jsonResult = jsonDecode(result.stdout as String);
        return QRGenerationResult.fromJson(jsonResult);
      } else {
        return QRGenerationResult(
          success: false,
          error: result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : result.stdout.toString(),
        );
      }
    } catch (e) {
      return QRGenerationResult(
        success: false,
        error: 'Failed to execute QR generator: $e',
      );
    }
  }

  /// Generate WiFi QR code
  static Future<QRGenerationResult> generateWifiQR({
    required String ssid,
    String password = '',
    String security = 'WPA',
    String? outputPath,
    int size = 512,
    String style = 'square',
  }) async {
    try {
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        return QRGenerationResult(
          success: false,
          error: 'QR generator script not found at $_scriptPath',
        );
      }

      final args = [
        scriptFile.absolute.path,
        '--wifi',
        '--ssid',
        ssid,
        '--password',
        password,
        '--security',
        security,
        '--size',
        size.toString(),
        '--style',
        style,
        '--json',
      ];

      if (outputPath != null) {
        args.addAll(['--output', outputPath]);
      }

      // Try python first, then python3
      ProcessResult result;
      try {
        result = await Process.run('python', args,
            workingDirectory: Directory.current.path);
      } catch (e) {
        result = await Process.run('python3', args,
            workingDirectory: Directory.current.path);
      }

      if (result.exitCode == 0) {
        final jsonResult = jsonDecode(result.stdout as String);
        return QRGenerationResult.fromJson(jsonResult);
      } else {
        return QRGenerationResult(
          success: false,
          error: result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : result.stdout.toString(),
        );
      }
    } catch (e) {
      return QRGenerationResult(
        success: false,
        error: 'Failed to execute QR generator: $e',
      );
    }
  }

  /// Generate vCard QR code
  static Future<QRGenerationResult> generateVCardQR({
    required String name,
    String phone = '',
    String email = '',
    String organization = '',
    String url = '',
    String? outputPath,
    int size = 512,
    String style = 'square',
  }) async {
    try {
      final scriptFile = File(_scriptPath);
      if (!await scriptFile.exists()) {
        return QRGenerationResult(
          success: false,
          error: 'QR generator script not found at $_scriptPath',
        );
      }

      final args = [
        scriptFile.absolute.path,
        '--vcard',
        '--name',
        name,
        '--phone',
        phone,
        '--email',
        email,
        '--organization',
        organization,
        '--url',
        url,
        '--size',
        size.toString(),
        '--style',
        style,
        '--json',
      ];

      if (outputPath != null) {
        args.addAll(['--output', outputPath]);
      }

      // Try python first, then python3
      ProcessResult result;
      try {
        result = await Process.run('python', args,
            workingDirectory: Directory.current.path);
      } catch (e) {
        result = await Process.run('python3', args,
            workingDirectory: Directory.current.path);
      }

      if (result.exitCode == 0) {
        final jsonResult = jsonDecode(result.stdout as String);
        return QRGenerationResult.fromJson(jsonResult);
      } else {
        return QRGenerationResult(
          success: false,
          error: result.stderr.toString().isNotEmpty
              ? result.stderr.toString()
              : result.stdout.toString(),
        );
      }
    } catch (e) {
      return QRGenerationResult(
        success: false,
        error: 'Failed to execute QR generator: $e',
      );
    }
  }
}

class QRGenerationResult {
  final bool success;
  final String? error;
  final String? message;
  final String? outputPath;
  final String? base64;
  final String? size;
  final String? format;

  QRGenerationResult({
    required this.success,
    this.error,
    this.message,
    this.outputPath,
    this.base64,
    this.size,
    this.format,
  });

  factory QRGenerationResult.fromJson(Map<String, dynamic> json) {
    return QRGenerationResult(
      success: json['success'] ?? false,
      error: json['error'],
      message: json['message'],
      outputPath: json['output_path'],
      base64: json['base64'],
      size: json['size'],
      format: json['format'],
    );
  }

  /// Get image bytes from base64 if available
  Uint8List? get imageBytes {
    if (base64 != null) {
      try {
        return base64Decode(base64!);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
