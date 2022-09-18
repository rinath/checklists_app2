import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/util/constants.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

Future<void> openInDefaultApp(String filenameE) async {
  if (Platform.isAndroid) {
    await OpenFile.open(filenameE);
  } else if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', filenameE]);
  } else {
    throw Exception('Platform docx preview not supported');
  }
  log('done running');
}

// Future<void> previewDocx(Map data, String filenameE) async {
//   var dir = await getTemporaryDirectory();
//   if (Platform.isAndroid) {
//     OpenFile.open(filenameE);
//   } else if (Platform.isWindows) {
//     var result = await Process.run('cmd', ['/c', 'start', filenameE]);
//   } else {
//     throw Exception('Platform docx preview not supported');
//   }
//   log('done running');
// }

// Future<String> generateDocx(Map data, String filePath, String docname) async {
//   log('trying to generate $filePath, docname: $docname, data: $data');
//   final docFullFilename = path.join(filePath, '$docname.docx');
//   final f = await File(docFullFilename).readAsBytes();
//   final docx = await DocxTemplate.fromBytes(f);
//   Content c = Content();
//   for (var form in data['forms']) {
//     if (form['type'] == 'list') {
//       var formName = form['name'];
//       var formFields = form['fields'];
//       for (var field in formFields) {
//         log('field: $field');
//         if (field['type'] == 'text') {
//           var fieldValue = field['value'];
//           var fieldTag = field['tag'];
//           c.add(TextContent(fieldTag, fieldValue));
//         }
//       }
//     }
//   }
//   final d = await docx.generate(c);
//   final generatedDocFilename = path.join(filePath, 'generated.docx');
//   final of = File(generatedDocFilename);
//   if (d != null) await of.writeAsBytes(d);
//   // idling:
//   // http.Response response = await http.get(Uri.parse('https://www.vk.com/'));
//   // log('response: ${response.body}');
//   previewDocx(generatedDocFilename);
//   return docFullFilename;
// }

// enum FolderType { temp, download, appdata }

// Future<Uint8List> generateDocument(
//     Map formData, Uint8List docxTemplateBytes) async {
//   final docx = await DocxTemplate.fromBytes(docxTemplateBytes);
//   Content c = Content();
//   for (var form in formData['forms']) {
//     if (form['type'] == 'list') {
//       var formFields = form['fields'];
//       for (var field in formFields) {
//         log('field: $field');
//         if (field['type'] == 'text') {
//           var fieldValue = field['value'];
//           var fieldTag = field['tag'];
//           c.add(TextContent(fieldTag, fieldValue));
//         }
//       }
//     }
//   }
//   final d = await docx.generate(c);
//   if (d == null) throw Exception('Failed to generate document');
//   return Uint8List.fromList(d);
// }

// Future<String> saveDoc(Future? futureData, filename, FolderType type) async {
//   var dir;
//   if (type == FolderType.appdata) {
//     dir = await getApplicationSupportDirectory();
//   } else if (type == FolderType.temp) {
//     dir = await getTemporaryDirectory();
//   } else if (type == FolderType.download) {
//     dir = await getDownloadsDirectory();
//   } else {
//     throw Exception('FolderType not supported');
//   }
//   var fileFolder = '${dir.path}/';
//   var filePath = '$fileFolder/$filename.json';
//   var file = File(filePath);
//   var data = await futureData;
//   JsonEncoder encoder = const JsonEncoder.withIndent('  ');
//   file.writeAsString(encoder.convert(data));
//   log('written to file $filePath');

//   ByteData docxTemplateBytes =
//       await rootBundle.load('assets/docx/$filename.docx');
//   File docxFile = await File('$fileFolder/$filename.docx').create();
//   await docxFile.writeAsBytes(docxTemplateBytes.buffer.asUint8List());
//   log('written to file $filePath');
//   return fileFolder;
// }

Future<void> saveJson(Map data, String docName) async {
  log(data.toString());
  final docFolder = await getDocFolder(docName);
  final jsonFile = File('$docFolder/$docName.json');
  final oldData = jsonDecode(await jsonFile.readAsString());
  final encoder = JsonEncoder.withIndent('  ');
  log('before json: ${encoder.convert(oldData)}');
  oldData.addAll(data);
  String prettyPrint = encoder.convert(oldData);
  await jsonFile.writeAsString(prettyPrint);
  log('after json: ${encoder.convert(oldData)}');
}

Future<String> createZipFromAsset(String filename) async {
  final tempDir0 = await getTemporaryDirectory();
  final tempDir = path.join(tempDir0.path, 'eokz');
  final appData0 = await getApplicationSupportDirectory();
  final appData = appData0.path;
  final zipFilename = '$appData/$filename.$zipExtension';
  var encoder = ZipFileEncoder();
  encoder.create(zipFilename);
  for (var ext in ['json', 'docx']) {
    final fileBytes = await rootBundle.load('assets/docx/$filename.$ext');
    // copy file to temp dir
    final file = await File('$tempDir/$filename.$ext').create(recursive: true);
    await file.writeAsBytes(fileBytes.buffer.asUint8List());
    encoder.addFile(file);
  }
  encoder.close();
  log('app data path: $appData');
  for (var file in await appData0.list().toList()) {
    log('$file');
  }
  return zipFilename;
}

Future<String> createDocFolderFromAsset(String filename) async {
  final appData = await getApplicationSupportDirectory();
  final docFolder = '${appData.path}/docs/$filename/';
  for (var ext in ['json', 'docx']) {
    final fileBytes = await rootBundle.load('assets/docx/$filename.$ext');
    final file =
        await File('$docFolder/$filename.$ext').create(recursive: true);
    await file.writeAsBytes(fileBytes.buffer.asUint8List());
  }
  log('app data path: ${appData.path}, contents:');
  final docFolderFile = Directory(docFolder);
  for (var file in await docFolderFile.list().toList()) {
    log('$file');
  }
  return docFolder;
}

enum FolderType { temp, appdata }

Future<String> getFolderPath(FolderType type) async {
  if (type == FolderType.appdata) {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  } else if (type == FolderType.temp) {
    final dir = await getTemporaryDirectory();
    return dir.path;
  } else {
    throw Exception('FolderType not supported');
  }
}

Future<String> getDocFolder(String docName) async {
  final appData = await getApplicationSupportDirectory();
  final docFolder = '${appData.path}/docs/$docName/';
  return docFolder;
}

// ex: filenameE='assets/docx/repair_card.json'
// E in filenameE means filename with extension
Future<String> copyAssetToFolder(String filenameE,
    [FolderType folderType = FolderType.temp]) async {
  final folderPath = await getFolderPath(folderType);
  final fileBytes = await rootBundle.load(filenameE);
  final outputFilename = '$folderPath/$filenameE';
  final file = await File(outputFilename).create(recursive: true);
  await file.writeAsBytes(fileBytes.buffer.asUint8List());
  return outputFilename;
}
