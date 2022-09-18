// list of tiles such as repair_card, repair_card_2, repair_card_3, etc.
// import 'dart:developer';
// import 'dart:math';

import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/mcoffice.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'editor.dart';

// import 'editor.dart';

class TemplateChooser extends StatelessWidget {
  const TemplateChooser({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    var templateNames = ['repair_card', 'repair_card_2', 'repair_card_3'];
    var children = <Widget>[];
    for (var templateName in templateNames) {
      children.add(Padding(
        padding: const EdgeInsets.all(8.0),
        child: FileWidget(templateName),
      ));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.scuba_diving),
        //     onPressed: () async {
        //       var dir = await getTemporaryDirectory();
        //       log('temp dir path: ${dir.path}');
        //     },
        //   ),
        // ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: children,
      ),
    );
  }
}

// repair_card InkWell tile
class FileWidget extends StatefulWidget {
  final String docName;

  const FileWidget(this.docName, {super.key});

  @override
  State<FileWidget> createState() => _FileWidgetState();
}

class _FileWidgetState extends State<FileWidget> {
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;
    const shareAction = "share";
    const downloadAction = "download";

    return InkWell(
      onTap: () async {
        final str = await createDocFolderFromAsset(widget.docName);
        if (!mounted) {
          return;
        }
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => DocEditor(widget.docName)));
      },
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(widget.docName, style: textStyle),
            ),
          ),
          IconButton(
            // icon: const Icon(Icons.delete),
            icon: const ImageIcon(
              AssetImage('assets/images/mcword.png'),
              size: 48,
            ),
            onPressed: () async {
              var filePath = 'assets/docx/${widget.docName}.docx';
              String path = await copyAssetToFolder(filePath);
              await openInDefaultApp(path);
              log("previewing Word document");
            },
          ),
          PopupMenuButton(
            onSelected: (String value) {
              switch (value) {
                case shareAction:
                  log("share to");
                  break;
                case downloadAction:
                  log("downloading...");
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: downloadAction,
                child: Text("Download to this device"),
              ),
              PopupMenuItem(
                value: shareAction,
                child: Text("Share"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
