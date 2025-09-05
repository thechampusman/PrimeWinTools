import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'DataBase/ClipBoardDataBase.dart';
import 'dart:async';

class ClipboardPopup extends StatefulWidget {
  const ClipboardPopup({Key? key}) : super(key: key);

  @override
  State<ClipboardPopup> createState() => _ClipboardPopupState();
}

class _ClipboardPopupState extends State<ClipboardPopup> {
  List<Map<String, dynamic>> clipboardHistory = [];

  @override
  void initState() {
    super.initState();
    _configureWindow();
    _loadClipboardHistory();

    Timer(const Duration(seconds: 30), () async {
      if (mounted) {
        await windowManager.close();
      }
    });
  }

  Future<void> _configureWindow() async {
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(400, 600));
    await windowManager.setPosition(const Offset(100, 100));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);
    await windowManager.setTitle('PrimeWinTools Clipboard');
  }

  Future<void> _loadClipboardHistory() async {
    final dbHelper = ClipboardDatabase();
    List<Map<String, dynamic>> history = await dbHelper.getClipboardHistory();
    setState(() {
      clipboardHistory = history;
    });
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await windowManager.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2D2D2D),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF6366F1),
                    Color(0xFF8B5CF6),
                  ],
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.content_paste,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Clipboard History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () async {
                      await windowManager.close();
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: clipboardHistory.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.content_paste_off,
                            color: Colors.grey,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No clipboard history yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: clipboardHistory.length,
                      itemBuilder: (context, index) {
                        final item = clipboardHistory[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3D3D3D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.text_snippet,
                              color: Color(0xFF6366F1),
                              size: 18,
                            ),
                            title: Text(
                              item['text'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item['timestamp'] ?? '',
                              style: TextStyle(
                                color: Colors.grey.withOpacity(0.7),
                                fontSize: 11,
                              ),
                            ),
                            onTap: () async {
                              await _copyToClipboard(item['text'] ?? '');
                            },
                            trailing: IconButton(
                              onPressed: () async {
                                final dbHelper = ClipboardDatabase();
                                await dbHelper.deleteClipboardEntry(item['id']);
                                await _loadClipboardHistory();
                              },
                              icon: Icon(
                                Icons.delete_outline,
                                color: Colors.red.withOpacity(0.7),
                                size: 16,
                              ),
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
  }
}
