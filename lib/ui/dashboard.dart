import 'dart:io';

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
        // Navigation bar with icons and text
        Container(
          decoration: const BoxDecoration(
              color: Color(0xFF454342),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15))),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _onItemTapped(0),
                child: Container(
                  child: Row(
                    children: [
                      Icon(Icons.home,
                          color: _selectedIndex == 0
                              ? const Color(0xFFE76343)
                              : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Home",
                        style: TextStyle(
                          color: _selectedIndex == 0
                              ? const Color(0xFFE76343)
                              : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Row(
                  children: [
                    Icon(Icons.list_alt,
                        color: _selectedIndex == 1
                            ? const Color(0xFFE76343)
                            : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "Clip Board",
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? const Color(0xFFE76343)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40),
              GestureDetector(
                onTap: () => _onItemTapped(1),
                child: Row(
                  children: [
                    Icon(Icons.info,
                        color: _selectedIndex == 2
                            ? const Color(0xFFE76343)
                            : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "About",
                      style: TextStyle(
                        color: _selectedIndex == 2
                            ? const Color(0xFFE76343)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                ? const Homepage(key: ValueKey<int>(0)) // Home page content
                : _selectedIndex == 1
                    ? ClipboardScreen(
                        copiedItems: clipboardManager
                            .copiedItems, // Pass the actual clipboard items
                      ) // Clipboard page content
                    : const About(key: ValueKey<int>(2)), // About page content
          ),
        ),
      ],
    );
  }
}
