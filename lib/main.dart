import 'dart:io';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
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
        appBar: AppBar(
          title: Text('Windows File Cleaner'),
        ),
        body: FileCleanerHome(),
      ),
    );
  }
}

class FileCleanerHome extends StatefulWidget {
  @override
  _FileCleanerHomeState createState() => _FileCleanerHomeState();
}

class _FileCleanerHomeState extends State<FileCleanerHome> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Windows Temp File Cleaner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed:
                  scanTempFiles, // Connect the scan button to the function
              child: Text('Scan for Temp Files'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                cleanTempFiles();
              },
              child: Text('Clean Temp Files'),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: tempFiles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                        tempFiles[index]), // Displays both files and folders
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
