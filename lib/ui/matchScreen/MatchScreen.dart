import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MatchScreen extends StatefulWidget {
  final AppUser matchedUser;

  MatchScreen({Key key, this.matchedUser}) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  bool checkingConversationState = false;
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  Widget getStateBaseButton() {

    if (checkingConversationState) {
      RaisedButton(
        color: Color(COLOR_PRIMARY),
        child: Center(
          child: CircularProgressIndicator(),
        ),
        textColor: Colors.white,
        splashColor: Color(COLOR_PRIMARY_DARK),
        onPressed: () {

        },
        padding: EdgeInsets.only(top: 12, bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25.0),
          side: BorderSide(
            color: Color(COLOR_PRIMARY),
          ),
        ),
      );
    }

    return PrimaryButton(
      label: 'SEND A MESSAGE',
      onTap: () async {
        setState(() {
          checkingConversationState = true;
        });
        setState(() {
          checkingConversationState = true;
        });
        pushReplacement(context, 
          ChatScreen(
            chatWithUser: widget.matchedUser,
          ),
        );
      },
    );

  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);
    return Material(
      child: Stack(fit: StackFit.expand, children: <Widget>[
        CachedNetworkImage(
          imageUrl: widget.matchedUser.profilePictureURL,
          fit: BoxFit.cover,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40.0),
          child: Column(
            verticalDirection: VerticalDirection.up,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: GestureDetector(
                  onTap: () {
                    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom, SystemUiOverlay.top]);
                    Navigator.pop(context);
                  },
                  child: Text('KEEP SWIPING',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode(context) ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                  child: getStateBaseButton(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 16),
                child: Text('IT\'S A MATCH!',
                  style: TextStyle(
                    letterSpacing: 4,
                    color: Color(COLOR_PRIMARY_DARK),
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),
        )
      ]),
    );
  }
}
