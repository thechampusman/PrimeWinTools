import 'dart:io';

import 'package:PrimeWinTool/ui/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard/DataBase/ClipBoardDataBase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Set window to be transparent and frameless (Windows only)
  if (Platform.isWindows) {
    await windowManager.setBackgroundColor(Colors.transparent);
    await windowManager.setHasShadow(false);
 
    // await windowManager.setAsFrameless();
  }

  removeWindowTitle();
  final clipboardDb = ClipboardDatabase();
  await clipboardDb.database;
  runApp(const MyApp());

  trayManager.setIcon('assets/app_icon.ico');
  trayManager.setContextMenu(Menu(items: [
    MenuItem(key: 'show', label: 'Show'),
    MenuItem(key: 'exit', label: 'Exit'),
  ]));

  trayManager.addListener(MyTrayListener());
}

void removeWindowTitle() async {
  // Remove window title
  await windowManager.setTitle('PrimeWinTool');
}

class MyTrayListener with TrayListener {
  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit') {
      windowManager.destroy();
    }
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<bool> onWindowClose() async {
    // Hide window instead of closing
    await windowManager.hide();
    return false; // Prevent app from closing
  }

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
