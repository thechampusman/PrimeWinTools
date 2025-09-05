import 'package:flutter/material.dart';
import '../clipboard/DataBase/ClipBoardDataBase.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ClipboardOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  static void show(BuildContext context) {
    if (_isShowing) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      print('❌ No Overlay found in context');
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => const ClipboardPopupOverlay(),
    );

    overlay.insert(_overlayEntry!);
    _isShowing = true;
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
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadClipboardHistory() async {
    final dbHelper = ClipboardDatabase();
    List<Map<String, dynamic>> history = await dbHelper.getClipboardHistory();
    setState(() {
      clipboardHistory = history.take(10).toList();
    });
  }

  Future<void> _copyToClipboard(String text) async {
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
    return GestureDetector(
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
                            Expanded(
                              child: clipboardHistory.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                      itemCount: clipboardHistory.length,
                                      itemBuilder: (context, index) {
                                        final item = clipboardHistory[index];
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3D3D3D),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                const EdgeInsets.all(12),
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
                                            subtitle: Text(
                                              _formatTimestamp(
                                                  item['timestamp']),
                                              style: TextStyle(
                                                color: Colors.grey
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                            onTap: () async {
                                              await _copyToClipboard(
                                                  item['text'] ?? '');
                                            },
                                            trailing: IconButton(
                                              onPressed: () async {
                                                final dbHelper =
                                                    ClipboardDatabase();
                                                await dbHelper
                                                    .deleteClipboardEntry(
                                                        item['id']);
                                                await _loadClipboardHistory();
                                              },
                                              icon: Icon(
                                                Icons.delete_outline,
                                                color:
                                                    Colors.red.withOpacity(0.7),
                                                size: 18,
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
                    ),
                  ),
                ),
              );
            },
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
