// list of tiles such as repair_card, repair_card_2, repair_card_3, etc.
import 'dart:developer';

import 'package:flutter/material.dart';

import 'editor.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              log('save');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: children,
      ),
    );
  }
}

// repair_card InkWell tile
class FileWidget extends StatelessWidget {
  final String filename;

  const FileWidget(this.filename, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;
    const shareAction = "share";
    const downloadAction = "download";

    return InkWell(
      onTap: () async {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => DocEditor(filename)));
      },
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(filename, style: textStyle),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
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
