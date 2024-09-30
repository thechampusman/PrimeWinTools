import 'dart:io';

import 'package:PrimeWinTool/ui/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard/DataBase/ClipBoardDataBase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the window manager
  await windowManager.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit(); // Initialize FFI for desktop
    databaseFactory = databaseFactoryFfi; // Set database factory for FFI
  }
  // Remove the title and default window elements
  removeWindowTitle();
  final clipboardDb = ClipboardDatabase();
  await clipboardDb.database;
  runApp(const MyApp());
}

void removeWindowTitle() async {
  // Remove window title
  await windowManager.setTitle('PrimeWinTool');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PrimeWinTool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.red.withOpacity(0.0),
        body: const Dashboard(),
      ),
    );
  }
}
