import 'package:flutter/material.dart';

class MyInputField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final String label;
  final bool readOnly;
  final GestureTapCallback? onTap;
  final Widget? suffixIcon;
  final List<String>? suggestions;

  const MyInputField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.suffixIcon,
    this.suggestions,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions != null && suggestions!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            return suggestions!.where(
              (String option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            // Initialize only once
            if (textController.text != controller?.text) {
              textController.text = controller?.text ?? '';
              textController.selection = TextSelection.collapsed(
                offset: textController.text.length,
              );
            }

            textController.addListener(() {
              if (controller != null &&
                  controller!.text != textController.text) {
                controller!.text = textController.text;
              }
            });

            return TextField(
              enableSuggestions: true,
              controller: textController,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textCapitalization: TextCapitalization.words,
              readOnly: readOnly,
              onTap: onTap,
              decoration: InputDecoration(
                suffixIcon: suffixIcon,
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              onTapOutside: (event) => FocusScope.of(context).unfocus(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            );
          },
          onSelected: (value) => controller?.text = value,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: TextField(
          onTapOutside: (event) => FocusScope.of(context).unfocus(),
          controller: controller,
          onTap: onTap,
          readOnly: readOnly,
          keyboardType: keyboardType,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            suffixIcon: suffixIcon,
            labelText: label,
            border: const OutlineInputBorder(),
          ),
        ),
      );
    }
  }
}
