import 'dart:io';

import 'package:cleaner/dashboard.dart';
import 'package:cleaner/win32_blur.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();

  // Remove the title and default window elements
  removeWindowTitle();

  runApp(const MyApp());
}

void removeWindowTitle() async {
  // Remove window title
  await windowManager.setTitle('');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.red.withOpacity(0.0),
        body: const FileCleanerHome(),
      ),
    );
  }
}
