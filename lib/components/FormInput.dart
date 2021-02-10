import 'package:dating/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormInput extends StatelessWidget {
  
  final TextEditingController controller;
  final String label;
  final Function(String) onSubmitted;
  final TextInputType type;
  final bool obscureText;
  final TextInputAction textInputAction;
  final VoidCallback onTap;
  final bool readOnly;
  final Widget suffix;

  const FormInput({
    Key key, 
    this.controller,
    this.label,
    this.onSubmitted,
    this.onTap,
    this.type,
    this.obscureText = false,
    this.textInputAction,
    this.readOnly = false,
    this.suffix,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, right: 24.0, left: 24.0),
        child: TextField(
          textAlignVertical: this.type == TextInputType.multiline ? TextAlignVertical.top : TextAlignVertical.center,
          textInputAction: this.textInputAction,
          obscureText: this.obscureText,
          onSubmitted: this.onSubmitted,
          onTap: this.onTap,
          readOnly: this.readOnly,
          maxLines: this.type == TextInputType.multiline ? null : 1,
          expands: this.type == TextInputType.multiline,
          controller: controller,
          style: TextStyle(fontSize: 18.0),
          keyboardType: this.type,
          cursorColor: Color(COLOR_PRIMARY),
          inputFormatters: this.type != TextInputType.number ? null : [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            contentPadding: this.type == TextInputType.multiline ? EdgeInsets.symmetric(horizontal: 16, vertical: 14) : EdgeInsets.only(left: 16, right: 16),
            hintText: label,
            suffix: this.suffix,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(25.0),
              borderSide: BorderSide(
                color: Color(COLOR_PRIMARY),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).errorColor,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).errorColor,
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey[200],
              ),
              borderRadius: BorderRadius.circular(25.0),
            ),
          ),
        ),
      ),
    );
  }
}
