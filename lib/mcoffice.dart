import 'dart:developer';
import 'dart:io';

import 'package:docx_template/docx_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

Future<void> previewDocx(String filename) async {
  var result = await Process.run('cmd', ['/c', 'start', filename]);
  log('done running');
}

Future<String> generateDocx(Map data, String filePath, String docname) async {
  log('trying to generate $filePath, docname: $docname, data: $data');
  final docFullFilename = path.join(filePath, '$docname.docx');
  final f = await File(docFullFilename).readAsBytes();
  final docx = await DocxTemplate.fromBytes(f);
  Content c = Content();
  for (var form in data['forms']) {
    if (form['type'] == 'list') {
      var formName = form['name'];
      var formFields = form['fields'];
      for (var field in formFields) {
        log('field: $field');
        if (field['type'] == 'text') {
          var fieldValue = field['value'];
          var fieldTag = field['tag'];
          c.add(TextContent(fieldTag, fieldValue));
        }
      }
    }
  }
  final d = await docx.generate(c);
  final generatedDocFilename = path.join(filePath, 'generated.docx');
  final of = File(generatedDocFilename);
  if (d != null) await of.writeAsBytes(d);
  // idling:
  // http.Response response = await http.get(Uri.parse('https://www.vk.com/'));
  // log('response: ${response.body}');
  previewDocx(generatedDocFilename);
  return docFullFilename;
}
