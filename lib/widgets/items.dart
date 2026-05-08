import 'package:flutter/material.dart';
import 'package:tailor_mate/widgets/input_fields.dart';

class Items extends StatelessWidget {
  const Items({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InputField(
            label: 'Item Name',
            controller: TextEditingController(),
            keyboardType: TextInputType.text,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: InputField(
            label: 'Quantity',
            controller: TextEditingController(),
            keyboardType: TextInputType.number,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: InputField(
            label: 'Price ₹',
            controller: TextEditingController(),
            keyboardType: TextInputType.number,
          ),
        ),
      ],
    );
  }
}
