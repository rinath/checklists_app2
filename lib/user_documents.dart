// list of tiles such as repair_card, repair_card_2, repair_card_3, etc.
// import 'dart:developer';
// import 'dart:math';

import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/mcoffice.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import 'editor.dart';

class TemplateChooser extends StatefulWidget {
  const TemplateChooser({super.key, required this.title});

  final String title;

  @override
  State<TemplateChooser> createState() => _TemplateChooserState();
}

class _TemplateChooserState extends State<TemplateChooser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder(
        future: getDocsList(FolderType.assets),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasData) {
            final data = snapshot.data as List<Map<String, String>>;
            var children = <Widget>[];
            for (var templateName in data) {
              children.add(
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TemplateTile(templateName['docName']!),
                ),
              );
            }
            if (data.isEmpty) {
              return const Center(
                child: Text('No templates found'),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(8),
              children: children,
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

// ex: EO-04-WSH-PR-001-F-04 template tile
class TemplateTile extends StatefulWidget {
  final String docName;

  const TemplateTile(this.docName, {super.key});

  @override
  State<TemplateTile> createState() => _TemplateTileState();
}

class _TemplateTileState extends State<TemplateTile> {
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;
    return InkWell(
      onTap: () async {
        final docFolder = await getDocFolder(widget.docName);
        for (var ext in ['docx', 'json']) {
          await copyAssetToFolder(
              'assets/docs/${widget.docName}.$ext', docFolder);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DocEditor(docFolder, widget.docName)));
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
              // var generatedFile = await generateDoc(docName);
              try {
                final docFolder = await getFolderPath(FolderType.temp);
                final copiedFile = await copyAssetToFolder(
                    'assets/docs/${widget.docName}.docx', docFolder);
                await openInDefaultApp(copiedFile);
              } on Exception catch (e) {
                showSnackBar(
                    context, 'At first close microsoft word application');
              }
              // String path = await copyAssetToFolder(filePath);
              log("previewing Word document");
            },
          ),
        ],
      ),
    );
  }
}

// repair_card InkWell tile
class FileWidget extends StatefulWidget {
  final String docName;
  final String docFolder;

  const FileWidget(this.docFolder, this.docName, {super.key});

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
        // final str = await createDocFolderFromAsset(widget.docName);
        if (!mounted) {
          return;
        }
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    DocEditor(widget.docFolder, widget.docName)));
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
              try {
                var generatedFile =
                    await generateDoc(widget.docFolder, widget.docName);
                await openInDefaultApp(generatedFile);
                log("previewing Word document");
              } catch (e) {
                showSnackBar(
                    context, 'At fist close microsoft word application');
              }
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
            itemBuilder: (context) => [
              PopupMenuItem(
                value: downloadAction,
                child: const Text("Скачать .docx"),
                onTap: () async {
                  final filename =
                      await generateDoc(widget.docFolder, widget.docName);
                  await saveFileInDefaultFileManager(filename);
                },
              ),
              if (Platform.isAndroid || Platform.isIOS)
                PopupMenuItem(
                  value: shareAction,
                  child: const Text("Отправить .docx"),
                  onTap: () async {
                    final filename =
                        await generateDoc(widget.docFolder, widget.docName);
                    await shareFile(filename);
                  },
                ),
              // PopupMenuItem(
              //   value: shareAction,
              //   child: Text("Отправить .eokz"),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
