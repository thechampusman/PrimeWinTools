import 'package:PrimeWinTool/ui/about.dart';
import 'package:PrimeWinTool/cleaner/homepage.dart';
import 'package:PrimeWinTool/cleaner/win32_blur.dart';
import 'package:PrimeWinTool/qr_tool/qr_tool.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:window_manager/window_manager.dart';

import '../clipboard/ClipBoardManager.dart';
import '../clipboard/clipboard.dart';

import '../services/app_service_manager.dart';
import '../python_env/python_env_manager.dart';
import 'clipboard_overlay.dart';
import 'localhost_manager.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

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
  late final AppServiceManager _serviceManager;
  late final ClipboardManager clipboardManager;

  static BuildContext? _dashboardContext;

  @override
  void initState() {
    super.initState();
    _serviceManager = AppServiceManager();
    clipboardManager = _serviceManager.clipboardManager;

    _serviceManager.startClipboardMonitoring(() {
      if (mounted) {
        setState(() {});
      }
    });

    applyBlurEffect();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _dashboardContext = context;

    final screenWidth = MediaQuery.of(context).size.width;

    final isVerySmallScreen = screenWidth < 600;
    final isSmallScreen = screenWidth < 800;
    final isMediumScreen = screenWidth >= 800 && screenWidth < 1200;
    final isLargeScreen = screenWidth >= 1200 && screenWidth < 1600;

    final sidebarWidth = isVerySmallScreen
        ? 60.0
        : isSmallScreen
            ? screenWidth * 0.12
            : isMediumScreen
                ? screenWidth * 0.15
                : isLargeScreen
                    ? screenWidth * 0.18
                    : screenWidth * 0.20;

    final titleFontSize = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 12.0
            : isMediumScreen
                ? 14.0
                : isLargeScreen
                    ? 16.0
                    : 18.0;

    final navFontSize = isVerySmallScreen
        ? 0.0
        : isSmallScreen
            ? 10.0
            : isMediumScreen
                ? 12.0
                : isLargeScreen
                    ? 14.0
                    : 16.0;

    final iconSize = isVerySmallScreen
        ? 28.0
        : isSmallScreen
            ? 32.0
            : isMediumScreen
                ? 40.0
                : isLargeScreen
                    ? 48.0
                    : 56.0;

    final titleBarFontSize = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 11.0
            : isMediumScreen
                ? 12.0
                : isLargeScreen
                    ? 13.0
                    : 14.0;

    final navIconSize = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 16.0
            : isMediumScreen
                ? 18.0
                : isLargeScreen
                    ? 20.0
                    : 22.0;

    final headerPadding = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 12.0
            : isMediumScreen
                ? 16.0
                : 24.0;

    final navPadding = isVerySmallScreen
        ? 4.0
        : isSmallScreen
            ? 8.0
            : isMediumScreen
                ? 12.0
                : 16.0;

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.2),
      body: Column(
        children: [
          _CustomTitleBar(titleBarFontSize: titleBarFontSize),
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: sidebarWidth,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            right: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(headerPadding),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                        isVerySmallScreen ? 8 : 16),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      width: iconSize,
                                      height: iconSize,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  if (!isVerySmallScreen) ...[
                                    SizedBox(height: isSmallScreen ? 8 : 16),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: isSmallScreen ? 8 : 12,
                                          vertical: isSmallScreen ? 4 : 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1),
                                        borderRadius: BorderRadius.circular(
                                            isSmallScreen ? 6 : 8),
                                      ),
                                      child: Text(
                                        isSmallScreen
                                            ? 'PWTools'
                                            : 'PrimeWinTools',
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.all(navPadding),
                                child: Column(
                                  children: [
                                    _NavButton(
                                      icon: Icons.cleaning_services_outlined,
                                      label: isVerySmallScreen
                                          ? ''
                                          : 'System Cleaner',
                                      selected: _selectedIndex == 0,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 0),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 4 : 8),
                                    _NavButton(
                                      icon: Icons.content_paste_outlined,
                                      label: isVerySmallScreen
                                          ? ''
                                          : (isSmallScreen
                                              ? 'Clipboard'
                                              : 'Clipboard Manager'),
                                      selected: _selectedIndex == 1,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 1),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 4 : 8),
                                    _NavButton(
                                      icon: Icons.router,
                                      label:
                                          isVerySmallScreen ? '' : 'Localhost',
                                      selected: _selectedIndex == 2,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 2),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 4 : 8),
                                    _NavButton(
                                      icon: Icons.qr_code,
                                      label: isVerySmallScreen ? '' : 'QR Code',
                                      selected: _selectedIndex == 3,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 3),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 4 : 8),
                                    _NavButton(
                                      icon: Icons.folder_special,
                                      label: isVerySmallScreen
                                          ? ''
                                          : 'Python Envs',
                                      selected: _selectedIndex == 4,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 4),
                                    ),
                                    SizedBox(height: isVerySmallScreen ? 4 : 8),
                                    _NavButton(
                                      icon: Icons.info_outline,
                                      label: isVerySmallScreen ? '' : 'About',
                                      selected: _selectedIndex == 5,
                                      fontSize: navFontSize,
                                      iconSize: navIconSize,
                                      isCollapsed: isVerySmallScreen,
                                      onTap: () =>
                                          setState(() => _selectedIndex = 5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.transparent,
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(left: 16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (Widget child,
                                    Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: IndexedStack(
                                  index: _selectedIndex,
                                  children: [
                                    const Cleaner(key: ValueKey<int>(0)),
                                    ClipboardScreen(
                                      copiedItems:
                                          _serviceManager.clipboardItems,
                                      key: const ValueKey<int>(1),
                                    ),
                                    const LocalhostManager(
                                        key: ValueKey<int>(2)),
                                    const QRCodeTool(key: ValueKey<int>(3)),
                                    const PythonEnvManager(
                                        key: ValueKey<int>(4)),
                                    const About(key: ValueKey<int>(5)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _CustomTitleBar extends StatefulWidget {
  final double titleBarFontSize;

  const _CustomTitleBar({
    this.titleBarFontSize = 13.0,
  });

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
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  children: [
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
                    Tooltip(
                      message: 'Hide to System Tray',
                      child: _TrafficLightButton(
                        color: const Color(0xFF8B5CF6),
                        hoverColor: const Color(0xFF7C3AED),
                        icon: Icons.keyboard_arrow_down,
                        onTap: () async {
                          await windowManager.hide();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
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
              Expanded(
                child: GestureDetector(
                  onPanStart: (details) async {
                    await windowManager.startDragging();
                  },
                  child: Container(
                    height: double.infinity,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/app_icon.ico',
                            width: 16,
                            height: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PrimeWinTools',
                            style: TextStyle(
                              fontSize: widget.titleBarFontSize,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 100),
            ],
          ),
        ),
      ),
    );
  }
}

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

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double fontSize;
  final double iconSize;
  final bool isCollapsed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.fontSize = 14.0,
    this.iconSize = 20.0,
    this.isCollapsed = false,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 8 : 16,
              vertical: widget.isCollapsed ? 8 : 12),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFF3B82F6)
                : _hovering
                    ? const Color(0xFFE5E7EB)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(widget.isCollapsed ? 8 : 6),
          ),
          child: widget.isCollapsed
              ? Center(
                  child: Icon(
                    widget.icon,
                    color: widget.selected
                        ? Colors.white
                        : const Color(0xFF374151),
                    size: widget.iconSize,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.selected
                          ? Colors.white
                          : const Color(0xFF374151),
                      size: widget.iconSize,
                    ),
                    if (widget.label.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.label,
                          style: TextStyle(
                            color: widget.selected
                                ? Colors.white
                                : const Color(0xFF374151),
                            fontSize: widget.fontSize,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
