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

Map tagToForm(String tag, String type) {
  print('tag: $tag');
  final tempTag = {
    "v": ["mv", "v", "kv"],
    "a": ["ua", "ma", "a"],
    "ohm": ["uohm", "mohm", "ohm", "kohm", "mohm", "gohm"]
  };
  final dropdowns = [
    {
      "vxna": ["✓", "✗", "N/A"],
      "v": ["mV", "V", "KV"],
      "a": ["µA", "mA", "A"],
      "Ohm": ["µOhm", "mOhm", "Ohm", "kOhm", "MOhm", "GOhm"]
    },
    {
      "vxna": ["✓", "✗", "N/A"],
      "v": ["мВ", "В", "КВ"],
      "a": ["µА", "мА", "А"],
      "Ohm": ["µОм", "мОм", "Ом", "кОм", "МОм", "ГОм"]
    }
  ];
  var form = {
    'name': ['', ''],
    'tag': tag,
    'value': null
  };
  if (['text', 'float'].contains(type)) {
    form.addAll({
      'type': type,
    });
  } else if (['ohm', 'a', 'v'].contains(type)) {
    form.addAll({
      'type': 'float',
      'postfix': type,
      'postfix_ind': 2,
    });
  } else if (['vxna'].contains(type)) {
    form.addAll({
      'type': 'radio',
      'radio_type': type,
    });
  } else if (type == 'date') {
    form.addAll({
      'type': 'date',
    });
  } else {
    throw Exception('Invalid type: $type. tag: $tag');
  }
  return form;
}

// filename = 'a.docx'
Future<Map> generateMap(String filename) async {
  // ttype = ['text', 'longtext', 'float']
  // tvalue = ['1', '2']
  // rtype = ['vxna', 'pl']
  // rvalue [2, 1]

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
    var form = tagToForm(tag, type);
    forms[formNumber]['fields'].add(form);
  }
  final formsList = [];
  final sortedKeys = forms.keys.toList();
  sortedKeys.sort(((a, b) => int.parse(a).compareTo(int.parse(b))));
  for (var key in sortedKeys) {
    print('key: $key');
    formsList.add(forms[key]);
  }
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
}
