import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/mcoffice.dart';
import 'package:flutter_application_2/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import 'editor_form.dart';

// list of forms in json file such as Process repair card, Completed works, Uload photo
class DocEditor extends StatefulWidget {
  final String _filename;

  const DocEditor(this._filename, {super.key});

  @override
  State<DocEditor> createState() => _DocEditorState();
}

class _DocEditorState extends State<DocEditor> {
  late final Future? futureData;

  @override
  void initState() {
    super.initState();
    log('initState');
    futureData = rootBundle
        .loadString('assets/docx/${widget._filename}.json')
        .then(((value) {
      Map data = parseJsonDocument(value, 'en');
      return data;
    }));
    // future = http.get(Uri.parse('https://www.vk.com/'));
    log('initState: $futureData');
  }

  Future<String> _saveDoc() async {
    var dir = await getApplicationSupportDirectory();
    var fileFolder = '${dir.path}/';
    var filePath = '$fileFolder/${widget._filename}.json';
    var file = File(filePath);
    var data = await futureData;
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    file.writeAsString(encoder.convert(data));
    log('written to file $filePath');
    return fileFolder;
  }

  // save button, preview doc button, share button
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._filename),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save,
            ),
            onPressed: () {
              log('save pressed');
              _saveDoc();
            },
          ),
          IconButton(
            onPressed: () async {
              log('preview pressed');
              var fullFilename = await _saveDoc();
              var data = await futureData;
              var docxPath =
                  await generateDocx(data, fullFilename, widget._filename);
              log('file generated: $docxPath');
            },
            icon: const Icon(Icons.art_track_outlined),
          )
        ],
      ),
      body: WillPopScope(
        onWillPop: () async {
          var data = await futureData;
          log('finished filling doc: $data');
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
                  children.add(FormName(form));
                }
                return ListView(
                  padding: const EdgeInsets.all(30),
                  children: children,
                );
              } else if (snapshot.hasError) {
                return Text(
                  'Error loading file ${widget._filename}',
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
  final Map _data;
  const FormName(this._data, {super.key});

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
              if (_data['type'] == 'list') {
                return ListEditor(_data);
              } else {
                return Text('Unimplemented type ${_data['type']}');
              }
            },
          ),
        );
      },
      title: Text(_data['name'], style: textStyle),
      subtitle: Text(_data['type']),
    );
  }
}
