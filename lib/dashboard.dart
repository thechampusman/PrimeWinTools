import 'dart:io';

import 'package:cleaner/about.dart';
import 'package:cleaner/homepage.dart';
import 'package:cleaner/win32_blur.dart';
import 'package:flutter/material.dart';

class FileCleanerHome extends StatefulWidget {
  const FileCleanerHome({super.key});

  @override
  _FileCleanerHomeState createState() => _FileCleanerHomeState();
}

class _FileCleanerHomeState extends State<FileCleanerHome> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
          decoration: BoxDecoration(
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
                              ? Color(0xFFE76343)
                              : Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Home",
                        style: TextStyle(
                          color: _selectedIndex == 0
                              ? Color(0xFFE76343)
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
                    Icon(Icons.info,
                        color: _selectedIndex == 1
                            ? Color(0xFFE76343)
                            : Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      "About",
                      style: TextStyle(
                        color: _selectedIndex == 1
                            ? Color(0xFFE76343)
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
                ? Homepage(key: const ValueKey<int>(0)) // Home page content
                : About(key: const ValueKey<int>(1)), // About page content
          ),
        ),
      ],
    );
  }
}
