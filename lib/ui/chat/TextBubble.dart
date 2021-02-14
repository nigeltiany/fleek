import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/ui/chat/WidgetBubble.dart';
import 'package:flutter/material.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';

class TextBubble extends StatefulWidget {

  final MessageData messageData;

  const TextBubble({
    Key key,
    @required this.messageData,
  }) : super(key: key);

  @override
  _TextBubbleState createState() => _TextBubbleState(this.messageData);

}

class _TextBubbleState extends State<TextBubble> {

  final MessageData messageData;
  AppUser currentUser;
  KeyPair keyPair;

  _TextBubbleState(this.messageData);

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    keyPair = context.read<KeyPair>();
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<String>(
      future: Gecies.decrypt(keyPair.privateKeyBase64, messageData.content.content[currentUser.userID]),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.hasError) {
          return WidgetBubble(
            byCurrentUser:  messageData.senderID == currentUser.userID,
            child: Icon(Icons.error, color: Colors.redAccent),
          );
        }
        if (snapshot.data == null) {
          return Container();
        }
        return WidgetBubble(
          byCurrentUser: messageData.senderID == currentUser.userID,
          child: Text(snapshot.data,
            textAlign: TextAlign.start,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: isDarkMode(context) ? Colors.white : Colors.black,
              fontSize: 16,
            ),
          ),
        );
      },
    );

  }
}
