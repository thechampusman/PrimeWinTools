import 'dart:ui';

import 'package:PrimeWinTool/ui/about.dart';
import 'package:PrimeWinTool/cleaner/homepage.dart';
import 'package:PrimeWinTool/cleaner/win32_blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../clipboard/ClipBoardManager.dart';
import '../clipboard/clipboard.dart';
import 'clipboard_overlay.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  // Static method to show clipboard overlay from anywhere
  static void showClipboardOverlay() {
    if (_DashboardState._dashboardContext != null &&
        _DashboardState._dashboardContext!.mounted) {
      ClipboardOverlay.show(_DashboardState._dashboardContext!);
    }
  }

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  final ClipboardManager clipboardManager = ClipboardManager();

  // Static reference to dashboard context for global access
  static BuildContext? _dashboardContext;

  @override
  void initState() {
    super.initState();
    clipboardManager.monitorClipboard(() {
      setState(() {}); // Update the UI when clipboard changes
    });
    applyBlurEffect();
  }

  @override
  Widget build(BuildContext context) {
    // Store the context for global access
    _dashboardContext = context;

    final screenWidth = MediaQuery.of(context).size.width;
    final sidebarWidth = screenWidth * 0.18; // 18% of screen width

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // 🎨 Custom macOS-style Title Bar
          _CustomTitleBar(),
          // Main Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16, bottom: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFF3B82F6)
                          .withOpacity(0.03), // Very subtle cool blue
                      Colors.white,
                      const Color(0xFF8B5CF6)
                          .withOpacity(0.02), // Very subtle warm purple
                      Colors.white,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ), // Soft corners on right side only
                ),
                child: Row(
                  children: [
                    // 🎨 Left Sidebar (20% width) - FULLY TRANSPARENT
                    SizedBox(
                      width: sidebarWidth,
                      child: Column(
                        children: [
                          // Header
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // App icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.cleaning_services,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // App title
                                const Text(
                                  'PrimeWinTools',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Navigation buttons
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  _NavButton(
                                    icon: Icons.dashboard_outlined,
                                    label: 'Dashboard',
                                    selected: _selectedIndex == 0,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 0),
                                  ),
                                  const SizedBox(height: 8),
                                  _NavButton(
                                    icon: Icons.cleaning_services_outlined,
                                    label: 'System Cleaner',
                                    selected: _selectedIndex == 1,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 1),
                                  ),
                                  const SizedBox(height: 8),
                                  _NavButton(
                                    icon: Icons.content_paste_outlined,
                                    label: 'Clipboard Manager',
                                    selected: _selectedIndex == 2,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 2),
                                  ),
                                  const SizedBox(height: 8),
                                  _NavButton(
                                    icon: Icons.info_outline,
                                    label: 'About',
                                    selected: _selectedIndex == 3,
                                    onTap: () =>
                                        setState(() => _selectedIndex = 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 🎨 Right Content Area (80%) - Soft corners
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _selectedIndex == 0
                                ? const Homepage(key: ValueKey<int>(0))
                                : _selectedIndex == 1
                                    ? const Homepage(
                                        key: ValueKey<int>(1)) // System Cleaner
                                    : _selectedIndex == 2
                                        ? ClipboardScreen(
                                            copiedItems:
                                                clipboardManager.copiedItems,
                                            key: const ValueKey<int>(2),
                                          )
                                        : const About(key: ValueKey<int>(3)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 🎨 Custom macOS-style Title Bar Widget
class _CustomTitleBar extends StatefulWidget {
  @override
  State<_CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<_CustomTitleBar> {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    _checkMaximizedState();
  }

  Future<void> _checkMaximizedState() async {
    bool maximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() {
        _isMaximized = maximized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) async {
        await windowManager.startDragging();
      },
      child: MouseRegion(
        onEnter: (_) {},
        onExit: (_) {},
        child: Container(
          height: 32,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Row(
            children: [
              // 🎨 macOS-style Traffic Light Buttons (Left side)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    // Close Button (Red)
                    Tooltip(
                      message: 'Close',
                      child: _TrafficLightButton(
                        color: const Color(0xFFFF5F56),
                        hoverColor: const Color(0xFFFF3B30),
                        icon: Icons.close,
                        onTap: () async {
                          await windowManager.close();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Minimize Button (Yellow)
                    Tooltip(
                      message: 'Minimize',
                      child: _TrafficLightButton(
                        color: const Color(0xFFFFBD2E),
                        hoverColor: const Color(0xFFFF9500),
                        icon: Icons.remove,
                        onTap: () async {
                          await windowManager.minimize();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Maximize Button (Green)
                    Tooltip(
                      message: _isMaximized ? 'Restore' : 'Maximize',
                      child: _TrafficLightButton(
                        color: const Color(0xFF27C93F),
                        hoverColor: const Color(0xFF30D158),
                        icon: Icons.crop_square,
                        onTap: () async {
                          bool isMaximized = await windowManager.isMaximized();
                          if (isMaximized) {
                            await windowManager.unmaximize();
                          } else {
                            await windowManager.maximize();
                          }
                          await _checkMaximizedState();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // 🎨 Center Title Area (Draggable)
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) async {
                    await windowManager.startDragging();
                  },
                  child: Container(
                    height: double.infinity,
                    child: Center(
                      child: Text(
                        'PrimeWinTools',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Right side spacer to balance the layout
              const SizedBox(width: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 macOS Traffic Light Button Widget
class _TrafficLightButton extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final VoidCallback onTap;

  const _TrafficLightButton({
    required this.color,
    required this.hoverColor,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TrafficLightButton> createState() => _TrafficLightButtonState();
}

class _TrafficLightButtonState extends State<_TrafficLightButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _isHovering ? widget.hoverColor : widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: _isHovering
              ? Icon(
                  widget.icon,
                  size: 8,
                  color: Colors.black.withOpacity(0.6),
                )
              : null,
        ),
      ),
    );
  }
}

// Navigation Button Widget - TRANSPARENT VERSION
class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: widget.selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.9), // Cool indigo
                    const Color(0xFF8B5CF6).withOpacity(0.85), // Warm purple
                    const Color(0xFF3B82F6).withOpacity(0.9), // Cool blue
                  ],
                )
              : null, // NO BACKGROUND FOR NON-SELECTED
          borderRadius: BorderRadius.circular(16),
          border: widget.selected
              ? Border.all(
                  color: Colors.white.withOpacity(0.48),
                  width: 2,
                )
              : null, // NO BORDER FOR NON-SELECTED
          boxShadow: widget.selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(-2, -2),
                  ),
                ]
              : null, // NO SHADOW FOR NON-SELECTED
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 36,
              height: 36,
              decoration: widget.selected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.24),
                          Colors.white.withOpacity(0.12),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.24),
                        width: 1,
                      ),
                    )
                  : null, // NO DECORATION FOR NON-SELECTED
              child: Icon(
                widget.icon,
                color: widget.selected ? Colors.white : const Color(0xFF374151),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: widget.selected
                    ? BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.16),
                          width: 0.5,
                        ),
                      )
                    : null, // NO DECORATION FOR NON-SELECTED
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.selected
                        ? Colors.white
                        : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
