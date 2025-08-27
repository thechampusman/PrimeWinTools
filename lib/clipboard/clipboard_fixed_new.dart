import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'DataBase/ClipBoardDataBase.dart';

class ClipboardScreen extends StatefulWidget {
  final List<String> copiedItems;

  const ClipboardScreen({super.key, required this.copiedItems});

  @override
  _ClipboardScreenState createState() => _ClipboardScreenState();
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  List<Map<String, dynamic>> clipboardHistory = [];
  List<Map<String, dynamic>> filteredHistory = [];
  String searchQuery = '';
  Set<int> pinnedIds = {};

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
      filteredHistory = history;
      pinnedIds = history
          .where((e) => e['pinned'] == 1)
          .map<int>((e) => e['id'] as int)
          .toSet();
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      filteredHistory = clipboardHistory.where((entry) {
        return entry['text'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    });
  }

  void _togglePin(int id) async {
    final dbHelper = ClipboardDatabase();
    bool currentPinState = pinnedIds.contains(id);
    await dbHelper.updatePinStatus(id, currentPinState ? 0 : 1);
    await _loadClipboardHistory();
  }

  void _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard!')),
      );
    }
  }

  void _deleteEntry(int id) async {
    final dbHelper = ClipboardDatabase();
    await dbHelper.deleteClipboardEntry(id);
    await _loadClipboardHistory();
  }

  void _clearAll() async {
    final dbHelper = ClipboardDatabase();
    await dbHelper.clearClipboardHistory();
    await _loadClipboardHistory();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> entries) {
    Map<String, List<Map<String, dynamic>>> groups = {};
    for (var entry in entries) {
      String group;
      if (entry['pinned'] == 1) {
        group = 'Pinned';
      } else {
        DateTime date = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
        DateTime now = DateTime.now();
        if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day) {
          group = 'Today';
        } else if (date.year == now.year &&
            date.month == now.month &&
            date.day == now.day - 1) {
          group = 'Yesterday';
        } else {
          group =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        }
      }
      groups.putIfAbsent(group, () => []).add(entry);
    }

    if (groups.containsKey('Pinned')) {
      final pinned = groups.remove('Pinned')!;
      groups = {'Pinned': pinned, ...groups};
    }
    return groups;
  }

  void _editEntryDialog(Map<String, dynamic> item) async {
    final TextEditingController controller =
        TextEditingController(text: item['text']);
    final dbHelper = ClipboardDatabase();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Clipboard Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Edit your text...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      child: const Text("Save"),
                      onPressed: () async {
                        await dbHelper.updateClipboardEntry(
                            item['id'], controller.text);
                        Navigator.pop(context);
                        await _loadClipboardHistory();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Clipboard entry updated!')),
                          );
                        }
                      },
                    ),
                  ],
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
    final grouped = _groupByDate([
      ...filteredHistory.where((e) => e['pinned'] == 1),
      ...filteredHistory.where((e) => e['pinned'] != 1),
    ]);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header with title and clear button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.content_paste_outlined,
                  color: Color(0xFF1F2937),
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Clipboard History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Clear All",
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: clipboardHistory.isEmpty
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text("Clear All History?",
                                  style: TextStyle(color: Colors.white)),
                              content: const Text(
                                  "This will remove all clipboard entries.",
                                  style: TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  child: const Text("Cancel"),
                                  onPressed: () => Navigator.pop(ctx, false),
                                ),
                                TextButton(
                                  child: const Text("Clear All",
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                  onPressed: () => Navigator.pop(ctx, true),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) _clearAll();
                        },
                ),
              ],
            ),
          ),
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              style: const TextStyle(color: Color(0xFF1F2937)),
              decoration: InputDecoration(
                hintText: "Search clipboard...",
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          // Content area
          Expanded(
            child: clipboardHistory.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.content_paste_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No clipboard history yet.",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Copy something to get started!",
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView(
                      children: grouped.entries.expand<Widget>((group) {
                        final groupName = group.key;
                        final entries = group.value;
                        List<Widget> widgets = [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              groupName,
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ];
                        widgets.addAll(entries.map<Widget>((item) {
                          String text = item['text'];
                          DateTime timestamp =
                              DateTime.fromMillisecondsSinceEpoch(
                                  item['timestamp']);
                          int id = item['id'];
                          bool pinned = item['pinned'] == 1;
                          int length = text.length;

                          IconData entryIcon = Icons.text_fields;
                          Color iconColor = Colors.blue;
                          if (text.startsWith('http')) {
                            entryIcon = Icons.link;
                            iconColor = Colors.green;
                          } else if (text.trim().isEmpty) {
                            entryIcon = Icons.space_bar;
                            iconColor = Colors.grey;
                          } else if (RegExp(r'\d+').hasMatch(text)) {
                            entryIcon = Icons.numbers;
                            iconColor = Colors.orange;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color:
                                  pinned ? Colors.amber[50] : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pinned
                                    ? Colors.amber[200]!
                                    : Colors.grey[200]!,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                entryIcon,
                                color: iconColor,
                                size: 20,
                              ),
                              title: Text(
                                text.length > 50
                                    ? '${text.substring(0, 50)}...'
                                    : text,
                                style: const TextStyle(
                                  color: Color(0xFF1F2937),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                '${_formatTimestamp(timestamp)} • $length chars',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: pinned ? "Unpin" : "Pin",
                                    icon: Icon(
                                      pinned
                                          ? Icons.push_pin
                                          : Icons.push_pin_outlined,
                                      color: pinned
                                          ? Colors.amber[700]
                                          : Colors.grey[600],
                                    ),
                                    onPressed: () => _togglePin(id),
                                  ),
                                  IconButton(
                                    tooltip: "Edit",
                                    icon: Icon(Icons.edit,
                                        color: Colors.blue[600]),
                                    onPressed: () => _editEntryDialog(item),
                                  ),
                                  IconButton(
                                    tooltip: "Copy",
                                    icon: Icon(Icons.copy,
                                        color: Colors.green[600]),
                                    onPressed: () => _copyToClipboard(text),
                                  ),
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent),
                                    onPressed: () => _deleteEntry(id),
                                  ),
                                ],
                              ),
                              onTap: () => _editEntryDialog(item),
                            ),
                          );
                        }));
                        return widgets;
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
