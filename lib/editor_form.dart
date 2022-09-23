import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_application_2/util/constants.dart';

class ListEditor extends StatefulWidget {
  final Map data, formData;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  ListEditor(this.data, this.formData, {super.key});

  @override
  State<ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends State<ListEditor> {
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    final textStyleLarge = Theme.of(context).textTheme.titleLarge;
    var children = <Widget>[];
    // log('ListFormState');
    // log(widget.data.toString());
    var firstForm = true;
    for (var field in widget.formData['fields']) {
      if (firstForm) {
        firstForm = false;
      } else {
        children.add(const Divider());
      }
      children.add(
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListField(widget.data, field),
        ),
      );
    }

    final title = widget.formData['name'][Lang.langIndex];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Форма'),
      ),
      body: WillPopScope(
        onWillPop: () {
          log('trying to validate the form');
          if (!widget._formKey.currentState!.validate()) {
            log('FAILED TO validate');
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Form(
          key: widget._formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: textStyleLarge,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(30),
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  children: children,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ListField extends StatefulWidget {
  final Map data, formData;
  const ListField(this.data, this.formData, {super.key});

  @override
  State<ListField> createState() => _ListFieldState();
}

class _ListFieldState extends State<ListField> {
  @override
  Widget build(BuildContext context) {
    log('listfield formdata: ${widget.formData}');
    final textStyle = Theme.of(context).textTheme.titleMedium;
    var children = <Widget>[
      Text(
        widget.formData['name'][Lang.langIndex],
        style: textStyle,
      )
    ];
    if (widget.formData.containsKey('type')) {
      var initialValue = widget.formData['value'] ?? '';
      children.add(TextFormField(
        decoration: InputDecoration(
            suffixText: widget.formData['type'] == 'float' ? 'Ohm' : null),
        textAlign: TextAlign.end,
        textInputAction: TextInputAction.next,
        initialValue: initialValue,
        onChanged: (text) {
          widget.formData['value'] = text;
        },
        keyboardType: TextInputType.number,
        validator: (value) {
          if (widget.formData['type'] == 'float') {
            log('float validator: $value');
            var res;
            try {
              res = double.parse(value!);
              log('parsing ok: $res');
            } catch (e) {
              log('parsing NOT ok');
              return 'Введите только число';
            }
          }
          return null;
        },
      ));
    }
    if (widget.formData.containsKey('dtype')) {
      final dropdownWidget = DropdownWidget(widget.data, widget.formData);
      children.add(dropdownWidget);
    }
    // return wrapped children with some spacing between them
    return Wrap(
      runSpacing: 12,
      children: children,
    );
  }
}

class DropdownWidget extends StatefulWidget {
  final Map data, formData;
  late final dropdown;
  int? dvalue;
  DropdownWidget(this.data, this.formData, {super.key}) {
    final String dropdownType = formData['dtype'];
    dropdown = data['dropdown'][Lang.langIndex][dropdownType];
    dvalue = formData['dvalue'];
  }

  @override
  State<DropdownWidget> createState() => _DropdownWidgetState();
}

class _DropdownWidgetState extends State<DropdownWidget> {
  @override
  Widget build(BuildContext context) {
    // final values = [...widget.dropdown];
    return Row(
      children: [
        for (var i = 0; i < widget.dropdown.length; i++)
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (widget.dvalue == i) {
                  widget.dvalue = null;
                  widget.formData.remove('dvalue');
                } else {
                  widget.dvalue = i;
                  widget.formData['dvalue'] = i;
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.dvalue == i
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).primaryColorLight,
            ),
            child: Text(widget.dropdown[i]),
          ),
      ],
    );
  }
}
