import 'dart:io';

import 'package:cleaner/win32_blur.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:win32/win32.dart';
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: Colors.red.withOpacity(0.0),
        body: FileCleanerHome(),
      ),
    );
  }
}

class FileCleanerHome extends StatefulWidget {
  const FileCleanerHome({super.key});

  @override
  _FileCleanerHomeState createState() => _FileCleanerHomeState();
}

class _FileCleanerHomeState extends State<FileCleanerHome> {
  @override
  void initState() {
    super.initState();
    applyBlurEffect(); // Call the blur effect function
  }

  List<String> tempFiles = [];
  void scanTempFiles() {
    List<String> tempDirectories = [
      Platform.environment['TEMP']!, // User's temp directory
      r'C:\Windows\Temp', // Windows temp directory
      r'C:\Windows\Prefetch', // Prefetch folder
    ];

    List<String> foundItems = []; // This will hold both files and folders

    for (String dirPath in tempDirectories) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          // List all files and folders in the directory
          dir.listSync().forEach((FileSystemEntity entity) {
            if (entity is File) {
              foundItems.add('File: ${entity.path}'); // Add file to the list
            } else if (entity is Directory) {
              foundItems
                  .add('Folder: ${entity.path}'); // Add folder to the list
            }
          });
        } catch (e) {
          print('Error accessing $dirPath: $e');
        }
      }
    }

    // Update the UI with the scanned files and folders
    setState(() {
      tempFiles = foundItems;
    });
  }

  // void minimizeWindow() {
  //   final hwnd = GetForegroundWindow();
  //   if (hwnd == 0) return;
  //   ShowWindow(hwnd, SW_MINIMIZE);
  // }

  // void maximizeWindow() {
  //   final hwnd = GetForegroundWindow();
  //   if (hwnd == 0) return;
  //   ShowWindow(hwnd, SHOW_WINDOW_CMD.SW_MAXIMIZE);
  // }

  // void closeWindow() {
  //   final hwnd = GetForegroundWindow();
  //   if (hwnd == 0) return;
  //   PostMessage(hwnd, WM_CLOSE, 0, 0);
  // }

  void cleanTempFiles() {
    for (String itemPath in tempFiles) {
      final file = File(itemPath.replaceFirst('File: ', ''));
      final folder = Directory(itemPath.replaceFirst('Folder: ', ''));

      try {
        // Check if it's a file or folder
        if (itemPath.startsWith('File: ')) {
          if (file.existsSync()) {
            file.deleteSync();
            print('Deleted file: $itemPath');
          } else {
            print('File not found: $itemPath');
          }
        } else if (itemPath.startsWith('Folder: ')) {
          if (folder.existsSync()) {
            folder.deleteSync(recursive: true);
            print('Deleted folder: $itemPath');
          } else {
            print('Folder not found: $itemPath');
          }
        }
      } catch (e) {
        print('Failed to delete $itemPath: $e');
      }
    }

    // Clear the list after cleaning
    setState(() {
      tempFiles.clear();
    });
  }

  // void _startDragging() {
  //   final hwnd = GetForegroundWindow(); // Gets the window handle
  //   SendMessage(
  //       hwnd, WM_SYSCOMMAND, SC_MOVE + HTCAPTION, 0); // Enables dragging
  // }

  // void _dragWindow() {
  //   // This will trigger the window to move when the user drags the custom toolbar.
  //   final hwnd = GetForegroundWindow();
  //   PostMessage(hwnd, WM_SYSCOMMAND, SC_MOVE + HTCAPTION, 0);
  // }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.transparent, // Background color for the blur effect
          ),
        ),
        Column(
          children: [
            // Container(
            //   height: 40,
            //   padding: EdgeInsets.symmetric(horizontal: 10),
            //   decoration: BoxDecoration(
            //     color: Colors.blueGrey,
            //     borderRadius:
            //         BorderRadius.vertical(bottom: Radius.circular(20)),
            //   ),
            //   child: Row(
            //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //     children: [
            //       Text('Custom Title Bar',
            //           style: TextStyle(color: Colors.white)),
            //       Row(
            //         children: [
            //           IconButton(
            //             icon: Icon(Icons.remove, color: Colors.white),
            //             onPressed: minimizeWindow,
            //           ),
            //           IconButton(
            //             icon: Icon(Icons.crop_square, color: Colors.white),
            //             onPressed: toggleMaximizeRestoreWindow,
            //           ),
            //           IconButton(
            //             icon: Icon(Icons.close, color: Colors.white),
            //             onPressed: closeWindow,
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: scanTempFiles,
                      child: const Text('Scan for Temp Files'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: cleanTempFiles,
                      child: const Text('Clean Temp Files'),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView.builder(
                        itemCount: tempFiles.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                              tempFiles[index],
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
