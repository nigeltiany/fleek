import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

class WidgetBubble extends StatefulWidget {

  final Widget child;
  final bool byCurrentUser;

  const WidgetBubble({
    Key key,
    @required this.byCurrentUser,
    @required this.child,
  }) : super(key: key);

  @override
  _WidgetBubbleState createState() => _WidgetBubbleState(this.child, this.byCurrentUser);
}

class _WidgetBubbleState extends State<WidgetBubble> {

  final Widget child;
  final bool byCurrentUser;

  _WidgetBubbleState(this.child, this.byCurrentUser);

  @override
  Widget build(BuildContext context) {
    Color colorElement = byCurrentUser ? Color(COLOR_ACCENT) : (isDarkMode(context) ? Colors.grey[600] : Colors.grey[300]);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomRight,
      children: <Widget>[
        Positioned(
          right: byCurrentUser ? -8 : null,
          left: byCurrentUser ? null : -8,
          bottom: 0,
          child: Image.asset(byCurrentUser ? 'assets/images/chat_arrow_right.png' : 'assets/images/chat_arrow_left.png',
            color: colorElement,
            height: 12,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 50,
            maxWidth: 200,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colorElement,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}
