import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/mcoffice.dart';
import 'package:flutter_application_2/user_documents.dart';
import 'package:path_provider/path_provider.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:path/path.dart' as path;
// import 'editor.dart';

void main() async {
  runApp(const MyApp());
  // if (Platform.isWindows) {
  //   await DesktopWindow.setWindowSize(const Size(400, 700));
  // }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои документы'),
        actions: [
          IconButton(
            onPressed: () async {
              final docsFolder =
                  path.join(await getFolderPath(FolderType.appdata), 'docs');
              try {
                for (var dir in await Directory(docsFolder).list().toList()) {
                  log('deleting folder: ${dir.path}');
                  await dir.delete(recursive: true);
                }
              } on Exception catch (e) {
                // print error log:
                log('error deleting files: $e');
              }
              setState(() {});
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: FutureBuilder(
        future: getDocsList(FolderType.appdata),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var files = snapshot.data as List<Map<String, String>>;
            if (files.isEmpty) {
              return const Center(child: Text('No documents found'));
            }
            return ListView.builder(
              itemCount: files.length,
              itemBuilder: (context, index) {
                // return ListTile(
                //   title: Text(files[index]),
                // );
                return FileWidget(
                    files[index]['docFolder']!, files[index]['docName']!);
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
              return const TemplateChooser(title: 'Выберите шаблон');
            }),
          ).then((value) => setState(() {}));
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }
}
