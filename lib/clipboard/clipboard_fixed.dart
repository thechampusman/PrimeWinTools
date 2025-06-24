import 'dart:ui';
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
    final entry = clipboardHistory.firstWhere((e) => e['id'] == id);
    final newPin = entry['pinned'] == 1 ? 0 : 1;
    await dbHelper.updatePinStatus(id, newPin);
    await _loadClipboardHistory();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _deleteEntry(int id) async {
    final dbHelper = ClipboardDatabase();
    await dbHelper.deleteClipboardEntry(id);
    setState(() {
      clipboardHistory.removeWhere((e) => e['id'] == id);
      filteredHistory.removeWhere((e) => e['id'] == id);
    });
  }

  void _clearAll() async {
    final dbHelper = ClipboardDatabase();
    await dbHelper.clearClipboardHistory();
    setState(() {
      clipboardHistory.clear();
      filteredHistory.clear();
    });
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> entries) {
    Map<String, List<Map<String, dynamic>>> groups = {};
    final now = DateTime.now();
    for (var entry in entries) {
      final date = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
      String group;
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
    final ScrollController scrollController = ScrollController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black.withOpacity(1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 1000),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return const LinearGradient(
                          colors: [Color(0xFF43CEA2), Color(0xFF185A9D)],
                        ).createShader(bounds);
                      },
                      child: const Icon(Icons.edit, size: 28, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Edit Clipboard Entry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 810),
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: scrollController,
                    child: TextField(
                      controller: controller,
                      scrollController: scrollController,
                      maxLines: null,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                      onPressed: () async {
                        await dbHelper.updateClipboardEntry(
                            item['id'], controller.text);
                        Navigator.of(context).pop();
                        await _loadClipboardHistory();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Clipboard entry updated!')),
                        );
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Clipboard History'),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        actions: [
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
                                style: TextStyle(color: Colors.redAccent)),
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
      body: Stack(
        children: [
          // Acrylic blur background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.black.withOpacity(0.18),
            ),
          ),
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 10000),
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: Column(
                children: [
                  TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Search clipboard...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: clipboardHistory.isEmpty
                        ? Center(
                            child: Text(
                              "No clipboard history yet.",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 18,
                              ),
                            ),
                          )
                        : ListView(
                            children: grouped.entries.expand<Widget>((group) {
                              final groupName = group.key;
                              final entries = group.value;
                              List<Widget> widgets = [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Text(
                                    groupName,
                                    style: const TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
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
                                Color iconColor = Colors.lightBlueAccent;
                                if (text.startsWith('http')) {
                                  entryIcon = Icons.link;
                                  iconColor = Colors.greenAccent;
                                } else if (text.trim().isEmpty) {
                                  entryIcon = Icons.not_interested;
                                  iconColor = Colors.grey;
                                }

                                return Dismissible(
                                  key: ValueKey(id),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (_) => _deleteEntry(id),
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 24),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.delete,
                                        color: Colors.redAccent, size: 28),
                                  ),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 350),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Transform.translate(
                                          offset: Offset(0, (1 - value) * 20),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _editEntryDialog(item),
                                      child: Card(
                                        color: Colors.white.withOpacity(0.10),
                                        elevation: 0,
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ListTile(
                                          leading: ShaderMask(
                                            shaderCallback: (Rect bounds) {
                                              return LinearGradient(
                                                colors: [
                                                  iconColor,
                                                  Colors.blueGrey
                                                ],
                                              ).createShader(bounds);
                                            },
                                            child: Icon(entryIcon,
                                                color: Colors.white, size: 28),
                                          ),
                                          title: Text(
                                            text,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          subtitle: Row(
                                            children: [
                                              Text(
                                                'Copied on: ${timestamp.toLocal()}',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.7),
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                '$length chars',
                                                style: TextStyle(
                                                  color: Colors.white
                                                      .withOpacity(0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: pinned
                                                    ? "Unpin"
                                                    : "Pin",
                                                icon: Icon(
                                                  pinned
                                                      ? Icons.star
                                                      : Icons.star_border,
                                                  color: pinned
                                                      ? Colors.orangeAccent
                                                      : Colors.white54,
                                                ),
                                                onPressed: () =>
                                                    _togglePin(id),
                                              ),
                                              IconButton(
                                                tooltip: "Copy",
                                                icon: const Icon(Icons.copy,
                                                    color:
                                                        Colors.lightGreenAccent),
                                                onPressed: () =>
                                                    _copyToClipboard(text),
                                              ),
                                              IconButton(
                                                tooltip: "Delete",
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.redAccent),
                                                onPressed: () =>
                                                    _deleteEntry(id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }));
                              return widgets;
                            }).toList(),
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
}
