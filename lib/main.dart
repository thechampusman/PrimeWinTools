import 'dart:io';

import 'package:PrimeWinTool/ui/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'clipboard/DataBase/ClipBoardDataBase.dart';
import 'services/hotkey_manager.dart';

// Global navigator key to access overlay from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Configure window for custom title bar
  if (Platform.isWindows) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // Hide the default title bar
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  removeWindowTitle();
  final clipboardDb = ClipboardDatabase();
  await clipboardDb.database;

  // Initialize global hotkeys
  await GlobalHotKeyManager.initialize();

  runApp(const MyApp());
  trayManager.setIcon('assets/app_icon.ico');
  trayManager.setToolTip('PrimeWinTools - Clipboard Manager');
  trayManager.setContextMenu(Menu(items: [
    MenuItem(
      key: 'show',
      label: 'Show PrimeWinTools',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'clipboard',
      label: 'Open Clipboard History',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit',
      label: 'Exit',
    ),
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
    _showAndFocusWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      _showAndFocusWindow();
    } else if (menuItem.key == 'clipboard') {
      _showAndFocusWindow();
      // TODO: Navigate directly to clipboard history
    } else if (menuItem.key == 'exit') {
      windowManager.destroy();
    }
  }

  void _showAndFocusWindow() async {
    await windowManager.show();
    await windowManager.focus();
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
    // Hide window to system tray instead of closing
    await windowManager.hide();
    return false; // Prevent app from closing
  }

  @override
  Future<bool> onWindowMinimize() async {
    // Hide to system tray when minimized
    await windowManager.hide();
    return false; // Prevent default minimize behavior
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'PrimeWinTool',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: const Dashboard(),
      ),
    );
  }
}
