import 'dart:convert';

// Map parseList(List l, int lang_index, int lang_num) {

// }

// Map parseMap(Map, int lang_index, int lang_num) {

// }

// Map parseJsonDocument(String jsonString, String lang) {
//   Map data = jsonDecode(jsonString);
//   var lang_index = data['langs'].indexOf(lang);
//   // for (var i = 0; i < data['forms'].length; i++) {
//   //   data['forms'][i]['name'] = data['forms'][i]['name'][lang_index];
//   //   if (data['forms'][i]['type'] == 'list') {
//   //     for (var j = 0; j < data['forms'][i]['fields'].length; j++) {
//   //       data['forms'][i]['fields'][j]['name'] =
//   //           data['forms'][i]['fields'][j]['name'][lang_index];
//   //     }
//   //   }
//   // }
//   return data;
// }

Map parseJsonDocument(String jsonString, String lang) {
  Map data = jsonDecode(jsonString);
  var lang_index = data['langs'].indexOf(lang);
  for (var i = 0; i < data['forms'].length; i++) {
    data['forms'][i]['name'] = data['forms'][i]['name'][lang_index];
    if (data['forms'][i]['type'] == 'list') {
      for (var j = 0; j < data['forms'][i]['fields'].length; j++) {
        data['forms'][i]['fields'][j]['name'] =
            data['forms'][i]['fields'][j]['name'][lang_index];
      }
    }
  }
  return data;
}
