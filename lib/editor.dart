import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_2/mcoffice.dart';
import 'package:flutter_application_2/util/constants.dart';
import 'package:path/path.dart' as path;

import 'editor_form.dart';

// list of forms in json file such as Process repair card, Completed works, Uload photo
class DocEditor extends StatefulWidget {
  final String docName;
  final String docFolder;

  const DocEditor(this.docFolder, this.docName, {super.key});

  @override
  State<DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<DocEditor> {
  late final Future? futureData;

  Future<Map> _loadDoc() async {
    String docFile =
        await File(path.join(widget.docFolder, '${widget.docName}.json'))
            .readAsString();
    Map data = jsonDecode(docFile);
    return data;
  }

  @override
  void initState() {
    super.initState();
    futureData = _loadDoc();
    log('initState: $futureData');
  }

  // save button, preview doc button, share button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docName),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
            ),
            onPressed: () async {
              log('save pressed');
              await saveJson(
                  await futureData, widget.docFolder, widget.docName);
              // await saveDoc();
              // var docs = await getDocsList(FolderType.appdata);
            },
          ),
          IconButton(
            onPressed: () async {
              await saveJson(
                  await futureData, widget.docFolder, widget.docName);
              try {
                String docFile =
                    await generateDoc(widget.docFolder, widget.docName);
                await openInDefaultApp(docFile);
                log('preview pressed: $docFile');
              } on Exception catch (e) {
                if (!mounted) return;
                showSnackBar(
                    context, 'At first close microsoft word application');
              }
            },
            icon: const ImageIcon(AssetImage('assets/images/mcword.png')),
          )
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          // var data = await futureData;
          // log('finished filling doc: $data');
          return true;
        },
        child: Center(
          child: FutureBuilder(
            future: futureData,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                Map data = snapshot.data;
                var children = <Widget>[];
                for (var form in data['forms']) {
                  children.add(FormName(data, form));
                }
                return ListView(
                  padding: const EdgeInsets.all(30),
                  children: children,
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading file ${widget.docName}',
                  style: const TextStyle(fontSize: 30),
                );
              } else {
                return const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

// form name such as "Fill General Info [list]"
class FormName extends StatelessWidget {
  final Map data, formData;
  const FormName(this.data, this.formData, {super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.headline6;
    return ListTile(
      onTap: () async {
        log('tapped');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              if (formData['type'] == 'list') {
                // log('listeditor data: $data');
                return ListEditor(data, formData);
              } else {
                return Text('Unimplemented type ${formData['type']}');
              }
            },
          ),
        );
      },
      title: Text(formData['name'][Lang.langIndex], style: textStyle),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.black, width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      // subtitle: Text(formData['type']),
    );
  }
}
