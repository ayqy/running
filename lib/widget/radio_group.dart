import 'package:flutter/material.dart';
import 'package:running/const/theme.dart';

class RadioGroup extends StatefulWidget {
  final List<Map> items;
  final dynamic value;
  final Function? onChange;

  const RadioGroup({Key? key, required this.items, required this.value, this.onChange}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RadioGroupState();
}

class RadioGroupState extends State<RadioGroup> {
  onRadioButtonPressed(Map item) {
    if (widget.onChange != null) {
      widget.onChange!(item['value'], item);
    }
  }

  List<Widget> _buildRadioButtons() {
    return widget.items.map((item) {
      bool isSelected = widget.value == item['value'];
      return GestureDetector(
        onTap: () {
          onRadioButtonPressed(item);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 2, 6, 2),
          decoration: BoxDecoration(
            color: Colors.white30,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? ThemeColors.selectedColor : Colors.transparent,
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: item['icon'] != null ? Icon(
            item['icon'],
            color: isSelected ? ThemeColors.selectedColor : Colors.black,
          ) : Text(
            item['label'],
            style: TextStyle(color: isSelected ? ThemeColors.selectedColor : Colors.black),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: _buildRadioButtons(),
      ),
    );
  }
}
