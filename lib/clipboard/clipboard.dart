import 'package:flutter/material.dart';

import 'DataBase/ClipBoardDataBase.dart';

class ClipboardScreen extends StatefulWidget {
  final List<String> copiedItems;

  const ClipboardScreen({super.key, required this.copiedItems});

  @override
  _ClipboardScreenState createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  List<Map<String, dynamic>> clipboardHistory = [];
  @override
  void initState() {
    super.initState();
    _loadClipboardHistory();
  }

  Future<void> _loadClipboardHistory() async {
    final dbHelper = ClipboardDatabase();
    List<Map<String, dynamic>> history = await dbHelper.getClipboardHistory();
    setState(() {
      clipboardHistory = history;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipboard History'),
      ),
      body: ListView.builder(
        itemCount: clipboardHistory.length,
        itemBuilder: (context, index) {
          var item = clipboardHistory[index];
          String text = item['text'];
          DateTime timestamp =
              DateTime.fromMillisecondsSinceEpoch(item['timestamp']);

          return ListTile(
            title: Text(text),
            subtitle: Text('Copied on: ${timestamp.toLocal()}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                // Optionally, implement delete functionality
              },
            ),
          );
        },
      ),
    );
  }
}
