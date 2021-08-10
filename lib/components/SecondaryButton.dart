import 'package:dating/components/ButtonType.dart';
import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

class SecondaryButton extends StatelessWidget {

  final String label;
  final VoidCallback onTap;
  final ButtonType buttonType;

  const SecondaryButton({
    Key key,
    this.label,
    this.onTap,
    this.buttonType = ButtonType.NORMAL,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      child: Text(label,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: buttonType == ButtonType.NORMAL ? Color(COLOR_PRIMARY) : Colors.redAccent,
        ),
      ),
      onPressed: onTap,
      padding: EdgeInsets.only(top: 12, bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
        side: BorderSide(
          color: buttonType == ButtonType.NORMAL ? (isDarkMode(context) ? Colors.white : Colors.black54) : Colors.redAccent,
        ),
      ),
    );
  }
}
