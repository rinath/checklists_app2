import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_2/util/constants.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

Future<void> openInDefaultApp(String filenameE) async {
  if (Platform.isAndroid || Platform.isIOS) {
    await OpenFile.open(filenameE);
  } else if (Platform.isWindows) {
    await Process.run('cmd', ['/c', 'start', filenameE]);
  } else {
    throw Exception('Platform docx preview not supported');
  }
  log('done running');
}

Future<String> generateDoc(String docFolder, String docName) async {
  final docxFullPath = path.join(docFolder, '$docName.docx');
  final docxTemplateBytes =
      (await File(docxFullPath).readAsBytes()).buffer.asUint8List();
  final jsonFullPath = path.join(docFolder, '$docName.json');
  final data = jsonDecode(await File(jsonFullPath).readAsString());
  log('generateDoc: jsonFullPath: $jsonFullPath, docxFullPath: $docxFullPath');
  Content c = Content();
  for (var form in data['forms']) {
    if (form['type'] == 'list') {
      var formFields = form['fields'];
      for (var field in formFields) {
        var fieldValueList = [];
        // if (field['type'] == 'text') {
        if (field.containsKey('value')) {
          fieldValueList.add(field['value'].toString());
        }
        if (field.containsKey('dvalue')) {
          var dvalueIndex = field['dvalue'];
          var dActualValue =
              data['dropdown'][Lang.langIndex][field['dtype']][dvalueIndex];
          fieldValueList.add(dActualValue.toString());
        }
        // }
        if (fieldValueList.isNotEmpty) {
          var str = fieldValueList.join('%');
          // log('changing tag: ${field['tag']}, fieldValue: ${field['value']}');
          var fieldTag = field['tag'];
          c.add(TextContent(fieldTag, str));
        }
      }
    }
  }
  final docx = await DocxTemplate.fromBytes(docxTemplateBytes);
  final d = await docx.generate(c, tagPolicy: TagPolicy.removeAll);
  if (d == null) throw Exception('Failed to generate document $docName');
  final tempFolder = await getFolderPath(FolderType.temp);
  final generatedDocFilename = path.join(tempFolder, 'eokz', '$docName.docx');
  await File(generatedDocFilename).writeAsBytes(d);
  return generatedDocFilename;
}

// ex: focFolder = '/data/user/0/com.example.eokz/app_flutter/FORM1/', docName = 'FORM1'
// saves data to file '/data/user/0/com.example.eokz/app_flutter/FORM1/FORM1.json'
Future<void> saveJson(Map data, String docFolder, String docName) async {
  log(data.toString());
  final String jsonFullPath = path.join(docFolder, '$docName.json');
  final File jsonFile = File(jsonFullPath);
  final oldData = jsonDecode(await jsonFile.readAsString());
  const JsonEncoder encoder = JsonEncoder.withIndent('  ');
  log('json full path: $jsonFullPath');
  log('before json: ${encoder.convert(oldData['forms'])}');
  oldData.addAll(data);
  String prettyPrinted = encoder.convert(oldData);
  await jsonFile.writeAsString(prettyPrinted, flush: true);
  final Map jsonFileReloaded =
      jsonDecode(await File(jsonFullPath).readAsString());
  log('after json: ${encoder.convert(jsonFileReloaded)}');
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
    final fileBytes = await rootBundle.load('assets/docs/$filename.$ext');
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

enum FolderType { temp, appdata, assets, root }

Future<String> getFolderPath(FolderType type) async {
  if (type == FolderType.appdata) {
    final dir = await getApplicationSupportDirectory();
    return dir.path;
  } else if (type == FolderType.temp) {
    final dir = await getTemporaryDirectory();
    return dir.path;
  } else if (type == FolderType.root) {
    final dir = await getExternalStorageDirectory();
    return dir!.path;
  } else {
    throw Exception('FolderType not supported');
  }
}

Future<String> getDocFolder(String docName) async {
  final appData =
      await (await getApplicationSupportDirectory()).create(recursive: true);
  final docFolder = '${appData.path}/docs/$docName/';
  return docFolder;
}

// ex: filenameE='assets/docx/repair_card.json'
// E in filenameE means filename with extension
Future<String> copyAssetToFolder(String filenameE, String folder) async {
  final fileBytes = await rootBundle.load(filenameE);
  final basename = path.basename(filenameE);
  final outputFilename = path.join(folder, basename);
  log('copying $filenameE to $outputFilename');
  final file = await File(outputFilename).create(recursive: true);
  await file.writeAsBytes(fileBytes.buffer.asUint8List());
  return outputFilename;
}

Future<List<Map<String, String>>> getDocsList(FolderType folderType) async {
  final List<Map<String, String>> docNames = [];
  if (folderType == FolderType.assets) {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = jsonDecode(manifestContent);
    final Set<String> docPaths = {};
    manifestMap.keys.toList().forEach((element) {
      if (element.contains('/docs/') && element.endsWith('.json')) {
        docPaths.add(path.basenameWithoutExtension(element));
      }
    });
    for (var element in docPaths) {
      docNames.add({'docName': element});
    }
  } else if (folderType == FolderType.appdata) {
    final folder = path.join(await getFolderPath(FolderType.appdata), 'docs');
    final files = await (await Directory(folder).create()).list().toList();
    log('getdocxlist of $folder:');
    for (var file in files) {
      log('file: ${file.path}');
      docNames
          .add({'docFolder': file.path, 'docName': path.basename(file.path)});
    }
  } else {
    throw Exception('FolderType not supported');
  }
  log('getdocslist: $docNames');
  return docNames;
}

Future<void> shareFile(String filename) async {
  await Share.shareFiles([filename]);
}

Future<void> saveFileInDefaultFileManager(String filename,
    {String allowedExtension = 'docx'}) async {
  String? result;
  if (Platform.isWindows) {
    result = await FilePicker.platform.saveFile(
        type: FileType.custom,
        allowedExtensions: [allowedExtension],
        fileName: path.basename(filename));
    if (result != null) {
      final bytes = await File(filename).readAsBytes();
      await File(result).writeAsBytes(bytes);
      log('file saved to $result');
    } else {
      log('file $result not saved');
    }
  } else if (Platform.isAndroid || Platform.isIOS) {
    final folderPath = await getFolderPath(FolderType.root);
    log('saving $filename in $folderPath');
    final params =
        SaveFileDialogParams(sourceFilePath: filename, localOnly: true);
    log(params.toString());
    result = await FlutterFileDialog.saveFile(params: params);
    if (result != null) {
      log('saved $filename in $result');
    } else {
      log('file $filename not saved');
    }
  } else {
    throw Exception('Platform not supported');
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message),
  ));
}
