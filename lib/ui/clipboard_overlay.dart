import 'package:flutter/material.dart';
import '../clipboard/DataBase/ClipBoardDataBase.dart';
import '../app/navigation_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ClipboardOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static bool show([BuildContext? context]) {
    if (_isShowing) return true;

    // Prefer overlay from provided context, else fall back to Navigator's overlay
    final overlay = (context != null ? Overlay.maybeOf(context) : null) ??
        navigatorKey.currentState?.overlay;
    if (overlay == null) {
      print('❌ No Overlay found in context or navigator');
      return false;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => const ClipboardPopupOverlay(),
    );

    overlay.insert(_overlayEntry!);
    _isShowing = true;
    return true;
  }

  static void hide() {
    if (!_isShowing) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isShowing = false;
  }
}

class ClipboardPopupOverlay extends StatefulWidget {
  const ClipboardPopupOverlay({Key? key}) : super(key: key);

  @override
  State<ClipboardPopupOverlay> createState() => _ClipboardPopupOverlayState();
}

class _ClipboardPopupOverlayState extends State<ClipboardPopupOverlay>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> clipboardHistory = [];
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _loadClipboardHistory();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
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
    ClipboardOverlay.hide();
  }

  Future<void> _copyPlainAndClose(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ClipboardOverlay.hide();
  }

  void _closeOverlay() {
    _animationController.reverse().then((_) {
      ClipboardOverlay.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> displayed = clipboardHistory
        .where((e) => (_searchController.text.isEmpty)
            ? true
            : (e['text'] ?? '')
                .toString()
                .toLowerCase()
                .contains(_searchController.text.toLowerCase()))
        .toList()
      ..sort((a, b) {
        final ap = (a['pinned'] ?? 0) as int;
        final bp = (b['pinned'] ?? 0) as int;
        if (ap != bp) return bp.compareTo(ap); // pinned first
        final at = (a['timestamp'] ?? 0) as int;
        final bt = (b['timestamp'] ?? 0) as int;
        return bt.compareTo(at); // newest first
      });

    if (_selectedIndex >= displayed.length) _selectedIndex = 0;

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.escape): const DismissIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
            _closeOverlay();
            return null;
          }),
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
            if (displayed.isNotEmpty) {
              _copyToClipboard(displayed[_selectedIndex]['text'] ?? '');
            }
            return null;
          }),
        },
        child: GestureDetector(
          onTap: _closeOverlay,
          child: Container(
            color: Colors.black.withOpacity(0.3),
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: GestureDetector(
                        onTap: () {},
                        child: Material(
                          color: Colors.transparent,
                          child: Focus(
                            autofocus: true,
                            onKeyEvent: (node, event) {
                              if (event is! KeyDownEvent) return KeyEventResult.ignored;
                              if (displayed.isEmpty) return KeyEventResult.ignored;
                              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                setState(() => _selectedIndex = (_selectedIndex + 1) % displayed.length);
                                return KeyEventResult.handled;
                              }
                              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                setState(() => _selectedIndex = (_selectedIndex - 1 + displayed.length) % displayed.length);
                                return KeyEventResult.handled;
                              }
                              if (event.logicalKey == LogicalKeyboardKey.delete) {
                                final item = displayed[_selectedIndex];
                                ClipboardDatabase().deleteClipboardEntry(item['id'] as int).then((_) => _loadClipboardHistory());
                                return KeyEventResult.handled;
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Container(
                              width: 400,
                              height: 500,
                              margin: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2D2D2D),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                    offset: const Offset(0, 15),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        topRight: Radius.circular(16),
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
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          'Clipboard History',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          onPressed: _closeOverlay,
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Search bar
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                    child: TextField(
                                      controller: _searchController,
                                      autofocus: true,
                                      onChanged: (_) => setState(() {}),
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        hintText: 'Search clips (Esc to close, Enter to copy)',
                                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
                                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                        filled: true,
                                        fillColor: const Color(0xFF3A3A3A),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: displayed.isEmpty
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
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(12),
                                            itemCount: displayed.length,
                                            itemBuilder: (context, index) {
                                              final item = displayed[index];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                decoration: BoxDecoration(
                                                  color: _selectedIndex == index
                                                      ? const Color(0xFF474B7A)
                                                      : const Color(0xFF3D3D3D),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.grey.withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: ListTile(
                                                  contentPadding: const EdgeInsets.all(12),
                                                  leading: const Icon(
                                                    Icons.text_snippet,
                                                    color: Color(0xFF6366F1),
                                                    size: 20,
                                                  ),
                                                  title: Text(
                                                    item['text'] ?? '',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  subtitle: Row(
                                                    children: [
                                                      if ((item['pinned'] ?? 0) == 1)
                                                        Container(
                                                          margin: const EdgeInsets.only(right: 8),
                                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFFFD166).withOpacity(0.15),
                                                            borderRadius: BorderRadius.circular(6),
                                                            border: Border.all(color: const Color(0xFFFFD166).withOpacity(0.4)),
                                                          ),
                                                          child: const Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.push_pin, size: 12, color: Color(0xFFFFD166)),
                                                              SizedBox(width: 4),
                                                              Text('Pinned', style: TextStyle(color: Color(0xFFFFD166), fontSize: 11)),
                                                            ],
                                                          ),
                                                        ),
                                                      Text(
                                                        _formatTimestamp(item['timestamp']),
                                                        style: TextStyle(
                                                          color: Colors.grey.withOpacity(0.7),
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  onTap: () async {
                                                    await _copyToClipboard(item['text'] ?? '');
                                                  },
                                                  trailing: Wrap(
                                                    spacing: 4,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Copy as plain text',
                                                        onPressed: () async {
                                                          await _copyPlainAndClose(item['text'] ?? '');
                                                        },
                                                        icon: const Icon(
                                                          Icons.text_format,
                                                          color: Colors.white70,
                                                          size: 18,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: (item['pinned'] ?? 0) == 1 ? 'Unpin' : 'Pin',
                                                        onPressed: () async {
                                                          final dbHelper = ClipboardDatabase();
                                                          final newVal = (item['pinned'] ?? 0) == 1 ? 0 : 1;
                                                          await dbHelper.updatePinStatus(item['id'] as int, newVal);
                                                          await _loadClipboardHistory();
                                                        },
                                                        icon: Icon(
                                                          (item['pinned'] ?? 0) == 1 ? Icons.push_pin : Icons.push_pin_outlined,
                                                          color: (item['pinned'] ?? 0) == 1 ? const Color(0xFFFFD166) : Colors.white70,
                                                          size: 18,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Delete',
                                                        onPressed: () async {
                                                          final dbHelper = ClipboardDatabase();
                                                          await dbHelper.deleteClipboardEntry(item['id'] as int);
                                                          await _loadClipboardHistory();
                                                        },
                                                        icon: Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red.withOpacity(0.7),
                                                          size: 18,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      try {
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
      } catch (e) {
        return timestamp;
      }
    } else {
      return timestamp.toString();
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
