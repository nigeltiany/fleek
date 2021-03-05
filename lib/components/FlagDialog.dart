import 'package:dating/model/Flag.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

class FlagDialog extends StatefulWidget {

  final Map<FlagReason, bool> valueStore;

  const FlagDialog({
    Key key,
    @required this.valueStore
  }) : super(key: key);

  @override
  _FlagDialogState createState() => _FlagDialogState();
}

class _FlagDialogState extends State<FlagDialog> {
  @override
  Widget build(BuildContext context) {
    var trueValues = widget.valueStore.entries.where((entry) => entry.value).map<FlagReason>((e) => e.key).toList(growable: false);
    String action;
    if (trueValues.isEmpty) {
      action = "Close";
    } else if (trueValues.length == 1 && trueValues[0] == FlagReason.GUT_FEELING) {
      action = "Swipe Left";
    } else {
      action = "Report";
    }
    return SimpleDialog(
      titlePadding: EdgeInsets.symmetric(horizontal: 8),
      title: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 64,
        leading: Icon(Icons.flag, color: Colors.red),
        title: Text("Flag Reason",
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
        ),
      ),
      children: FlagReason.values.map<Widget>((reason) {
        return CheckboxListTile(
          controlAffinity: ListTileControlAffinity.trailing,
          title: Text(reason.toFirebaseString().replaceAll("_", " ")),
          value: widget.valueStore[reason],
          onChanged: (newValue) {
            print(newValue);
            setState(() {
              widget.valueStore[reason] = newValue;
            });
          },
        );
      }).toList()..addAll([
        SizedBox(height: 16),
        FlatButton(onPressed: () => Navigator.of(context).pop(),
          child: Text(action),
        )
      ]),
    );
  }
}
