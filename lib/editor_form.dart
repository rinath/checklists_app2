import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class ListEditor extends StatefulWidget {
  final Map _data;
  const ListEditor(this._data, {super.key});

  @override
  State<ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends State<ListEditor> {
  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleMedium;
    var children = <Widget>[];
    // log('ListFormState');
    // log(widget.data.toString());
    for (var field in widget._data['fields']) {
      children.add(
        ListField(field),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget._data['name']),
      ),
      body: ListView(
        padding: const EdgeInsets.all(50),
        children: children,
      ),
    );
  }
}

class ListField extends StatefulWidget {
  final Map _data;
  const ListField(this._data, {super.key});

  @override
  State<ListField> createState() => _ListFieldState();
}

class _ListFieldState extends State<ListField> {
  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget._data['type'] == 'text') {
      var initialValue = '';
      if (widget._data.containsKey('value')) {
        initialValue = widget._data['value'];
      }
      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget._data['name']),
          TextFormField(
            textInputAction: TextInputAction.next,
            initialValue: initialValue,
            onChanged: (text) {
              widget._data['value'] = text;
            },
          ),
        ],
      );
    } else {
      child = Text('Unimplemented ${widget._data['name']}');
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: child,
    );
  }
}
