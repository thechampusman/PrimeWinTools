import 'dart:io';
import 'dart:ui';

import 'package:PrimeWinTool/ui/about.dart';
import 'package:PrimeWinTool/cleaner/homepage.dart';
import 'package:PrimeWinTool/cleaner/win32_blur.dart';
import 'package:flutter/material.dart';

import '../clipboard/ClipBoardManager.dart';
import '../clipboard/clipboard.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;
  final ClipboardManager clipboardManager = ClipboardManager();
  @override
  void initState() {
    super.initState();
    clipboardManager.monitorClipboard(() {
      setState(() {}); // Update the UI when clipboard changes
    });
    applyBlurEffect();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Modernized Navigation Bar
        Padding(
          padding: const EdgeInsets.only(top: 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF454342).withOpacity(0.85),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    _NavButton(
                      icon: Icons.home,
                      label: "Home",
                      selected: _selectedIndex == 0,
                      onTap: () => _onItemTapped(0),
                    ),
                    const SizedBox(width: 40),
                    _NavButton(
                      icon: Icons.list_alt,
                      label: "Clip Board",
                      selected: _selectedIndex == 1,
                      onTap: () => _onItemTapped(1),
                    ),
                    const SizedBox(width: 40),
                    _NavButton(
                      icon: Icons.info,
                      label: "About",
                      selected: _selectedIndex == 2,
                      onTap: () => _onItemTapped(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Animated content switcher
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _selectedIndex == 0
                ? const Homepage(key: ValueKey<int>(0))
                : _selectedIndex == 1
                    ? ClipboardScreen(
                        copiedItems: clipboardManager.copiedItems,
                        key: const ValueKey<int>(1),
                      )
                    : const About(key: ValueKey<int>(2)),
          ),
        ),
      ],
    );
  }
}

// Add this widget below your Dashboard class in the same file:
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
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFFE76343);
    final Color iconColor = widget.selected
        ? accent
        : (_hovering ? accent.withOpacity(0.7) : Colors.white);
    final Color textColor = widget.selected
        ? accent
        : (_hovering ? accent.withOpacity(0.7) : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..scale(widget.selected || _hovering ? 1.08 : 1.0),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: Icon(widget.icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  letterSpacing: 0.1,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
