import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docx_template/docx_template.dart';

List<String> splitAndCheckTag(String tag) {
  var splitted = tag.split('_');
  var type, formNumber;
  if (splitted.length < 3) {
    throw Exception(
        'Invalid tag split length of ${splitted.length}. tag: $tag');
  } else {
    type = splitted[splitted.length - 1];
    formNumber = splitted[splitted.length - 2];
    try {
      int.parse(formNumber);
    } catch (e) {
      throw Exception('Form number is not integer: $formNumber. tag: $tag');
    }
    if (!['float', 'text', 'vxna', 'v', 'a'].contains(type)) {
      throw Exception('Invalid type: $type. tag: $tag');
    }
  }
  return [type, formNumber];
}

// filename = 'a.docx'
Future<Map> generateMap(String filename) async {
  final file = File(filename);
  final bytes = await file.readAsBytes();
  final docx = await DocxTemplate.fromBytes(bytes);
  final tags = docx.getTags();
  final forms = {};
  final dropdown = [{}, {}];
  final types = [];
  for (var tag in tags) {
    var tmp = splitAndCheckTag(tag);
    var type = tmp[0], formNumber = tmp[1];
    types.add(type);
    if (!forms.containsKey(formNumber)) {
      forms[formNumber] = {
        'name': ['', ''],
        'type': 'list',
        'fields': [],
      };
    }
    forms[formNumber]['fields'].add({
      'name': ['', ''],
      'tag': tag,
      'type': type,
    });
  }
  final formsList = [];
  final sortedKeys = forms.keys.toList();
  sortedKeys.sort();
  for (var key in sortedKeys) {
    formsList.add(forms[key]);
  }
  final dropdowns = [
    {
      "vxna": ["✓", "✗", "N/A"],
      "v": ["mV", "V", "KV"],
      "a": ["microA", "mA", "A"]
    },
    {
      "vxna": ["✓", "✗", "N/A"],
      "v": ["мВ", "В", "КВ"],
      "a": ["микроА", "мА", "А"]
    }
  ];
  // get any lang string from dropdowns
  for (var type in types) {
    if (dropdowns[0].containsKey(type)) {
      for (var i = 0; i < dropdowns.length; i++) {
        dropdown[i][type] = dropdowns[i][type];
      }
    }
  }
  final map = {
    'langs': ['en', 'ru'],
    'version': '0.0.1',
    if (dropdown.isNotEmpty) 'dropdown': dropdown,
    'forms': formsList,
  };
  return map;
}

Future<void> saveJson(Map map, String filename) async {
  final file = File(filename);
  final encoder = JsonEncoder.withIndent('  ');
  await file.writeAsString(encoder.convert(map));
}

void main() async {
  final docName = 'EO-04-WSH-PR-001-F-04';
  final map = await generateMap('../assets/docs/$docName.docx');
  await saveJson(map, '$docName.json');
  // print(jsonEncode(map));
  final a = {
    'tag': 'tag_1_text',
    'type': 'text',
    'value': 'this is text',
    'dtype': 'vxna',
    'dvalue': 'N/A',
  };
}
