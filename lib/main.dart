import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/user_documents.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'editor.dart';

void main() async {
  runApp(const MyApp());
  if (Platform.isWindows) {
    await DesktopWindow.setWindowSize(const Size(400, 700));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // home: const TemplateChooser(title: 'EO Checklists'),
      home: const UserDocuments(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// list of all completed user documents
class UserDocuments extends StatefulWidget {
  const UserDocuments({super.key});

  @override
  State<UserDocuments> createState() => _UserDocumentsState();
}

class _UserDocumentsState extends State<UserDocuments> {
  Future? directory;

  Future<List<String>> _getFiles() async {
    var dir = await getApplicationSupportDirectory();
    log('PATH: ${dir.path}');
    var files = await dir.list().toList();
    var result = <String>[];
    for (var file in files) {
      result.add(file.path);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Documents'),
      ),
      body: FutureBuilder(
        future: _getFiles(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var files = snapshot.data as List<String>;
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(files[index]),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) {
              return const TemplateChooser(title: 'EO Checklists');
            }),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
