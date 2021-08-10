import 'package:dating/constants.dart';
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {

  final String label;
  final VoidCallback onTap;
  final Icon icon;

  const PrimaryButton({
    Key key,
    this.label,
    this.onTap,
  }) : icon = null, super(key: key);

  const PrimaryButton.icon({
    Key key,
    this.onTap,
    this.icon
  }) : this.label = null, super (key: key);

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      color: Color(COLOR_PRIMARY),
      child: icon == null ? Text(label ?? "",
        style: TextStyle(
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
      ) : icon,
      textColor: Colors.white,
      splashColor: Color(COLOR_PRIMARY_DARK),
      onPressed: onTap,
      padding: EdgeInsets.only(top: 12, bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25.0),
        side: BorderSide(
          color: Color(COLOR_PRIMARY),
        ),
      ),
    );
  }
}
