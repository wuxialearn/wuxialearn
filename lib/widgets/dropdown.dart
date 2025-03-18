import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DropDown extends StatefulWidget {
  final List<String> dropdownOptions;
  final Function(dynamic value) callback;
  const DropDown({
    super.key,
    required this.dropdownOptions,
    required this.callback,
  });

  @override
  State<DropDown> createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  String dropdownValue = "";

  @override
  void initState() {
    super.initState();
    dropdownValue = widget.dropdownOptions[0];
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: const Icon(Icons.arrow_downward),
      elevation: 16,
      style: const TextStyle(color: CupertinoColors.activeBlue),
      underline: Container(
        height: 2,
        color: CupertinoColors.activeBlue,
      ),
      onChanged: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          dropdownValue = value!;
        });
        widget.callback(dropdownValue);
      },
      items:
          widget.dropdownOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}
