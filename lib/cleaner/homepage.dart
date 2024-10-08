import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

class Homepage extends StatefulWidget {
  const Homepage({
    super.key,
  });

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<String> tempFiles = [];

  void scanTempFiles() {
    List<String> tempDirectories = [
      Platform.environment['TEMP']!,
      r'C:\Windows\Temp',
      r'C:\Windows\Prefetch',
    ];

    List<String> foundItems = [];

    for (String dirPath in tempDirectories) {
      final dir = Directory(dirPath);
      if (dir.existsSync()) {
        try {
          dir.listSync().forEach((FileSystemEntity entity) {
            if (entity is File) {
              foundItems.add('File: ${entity.path}');
            } else if (entity is Directory) {
              foundItems.add('Folder: ${entity.path}');
            }
          });
        } catch (e) {
          print('Error accessing $dirPath: $e');
          // Show a message to the user if a directory can't be accessed
          foundItems
              .add('Error accessing $dirPath: Requires Administrator Access');
        }
      }
    }

    setState(() {
      tempFiles = foundItems;
    });
  }

  void cleanTempFiles() async {
    final logFile = File('${Directory.current.path}\\log.txt');
    final now = DateTime.now();

    for (String itemPath in tempFiles) {
      final file = File(itemPath.replaceFirst('File: ', ''));
      final folder = Directory(itemPath.replaceFirst('Folder: ', ''));

      try {
        if (itemPath.startsWith('File: ')) {
          if (file.existsSync()) {
            file.deleteSync();
            logFile.writeAsStringSync('$now - Deleted File: $itemPath\n',
                mode: FileMode.append);
            print('Deleted file: $itemPath');
          } else {
            print('File not found: $itemPath');
          }
        } else if (itemPath.startsWith('Folder: ')) {
          if (folder.existsSync()) {
            folder.deleteSync(recursive: true);
            logFile.writeAsStringSync('$now - Deleted Folder: $itemPath\n',
                mode: FileMode.append);
            print('Deleted folder: $itemPath');
          } else {
            print('Folder not found: $itemPath');
          }
        }
      } catch (e) {
        print('Failed to delete $itemPath: $e');
        logFile.writeAsStringSync(
            '$now - Failed to delete: $itemPath, Error: $e\n',
            mode: FileMode.append);
      }
    }

    setState(() {
      tempFiles.clear();
    });
  }

  void _showLogHistory() async {
    final logFile = File('${Directory.current.path}\\log.txt');
    List<String> logEntries = [];

    // Check if the log file exists and read its contents
    if (logFile.existsSync()) {
      logEntries = logFile.readAsLinesSync();
    } else {
      logEntries = ['No log data found.'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.5),
          title: const Text(
            'Log History',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: logEntries.length,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display each log entry
                    Text(
                      logEntries[index],
                      style: const TextStyle(color: Colors.white),
                    ),
                    // Add a white line separator between log entries
                    const Divider(
                      color: Colors.white,
                      thickness: 1,
                    ),
                  ],
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white.withOpacity(0.1),
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color(0xFF454342).withOpacity(0.5),
                borderRadius: const BorderRadius.all(Radius.circular(7))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Your Personal Cleaner",
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          onPressed: _showLogHistory,
                          icon: const Icon(
                            Icons.history,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'View Log',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.white.withOpacity(0.4)),
                              backgroundColor: Colors.green),
                          onPressed: scanTempFiles,
                          icon: const Icon(
                            Icons.clear_all_outlined,
                            color: Colors.white,
                          ), // Clean icon for the scan button
                          label: const Text(
                            'Scan Files',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          onPressed: cleanTempFiles,
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ), // Delete icon for the clean button
                          label: const Text(
                            'Clean Files',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFF757675).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.6))),
                    child: ListView.builder(
                      itemCount: tempFiles.length,
                      itemBuilder: (context, index) {
                        bool isFile = tempFiles[index].startsWith('File: ');
                        bool isFolder = tempFiles[index].startsWith('Folder: ');
                        return ListTile(
                          leading: Icon(
                            isFile
                                ? Icons.insert_drive_file
                                : Icons.folder, // File or Folder icon
                            color: isFile ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            tempFiles[index],
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
