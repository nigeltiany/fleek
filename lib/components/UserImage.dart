import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserImage extends StatefulWidget {

  final UserWithImage userWithImage;

  const UserImage({
    Key key,
    @required this.userWithImage,
  }) : super(key: key);

  @override
  _UserImageState createState() => _UserImageState();

}

class _UserImageState extends State<UserImage> {

  @override
  Widget build(BuildContext context) {

    if (widget.userWithImage.profilePictureURL == null || widget.userWithImage.profilePictureURL.isEmpty) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Icon(
            Icons.account_circle,
            size: constraints.maxWidth * .8,
            color: isDarkMode(context) ? Colors.black : Colors.white,
          );
        },
      );
    }

    return _imageBuilder();

  }

  Widget _imageBuilder({ bool recursiveCall = false }) {

    return CachedNetworkImage(
      fit: BoxFit.cover,
      imageUrl: widget.userWithImage.profilePictureURL,
      progressIndicatorBuilder: (context, imageUrl, _) {
        return Icon(
          Icons.hourglass_empty,
          size: 75,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        );
      },
      errorWidget: (context, imageUrl, error) {
        var errorWidget = Icon(Icons.error_outline,
          size: 75,
          color: isDarkMode(context) ? Colors.black : Colors.white,
        );
        if (error is HttpException && !recursiveCall) {
          return _profileSource(errorWidget);
        }
        return errorWidget;
      },
    );

  }

  Widget _profileSource (Widget errorWidget) {
    var appUser = Provider.of<ConversationData>(context, listen: false).getUser(widget.userWithImage.userID);
    if (appUser == null) {
      return FutureBuilder<AppUser>(
        future: FireStoreUtils.getUserByID(widget.userWithImage.userID).then((user) {
          Provider.of<ConversationData>(context, listen: false).addConversationUser(user);
          widget.userWithImage.profilePictureURL = user.profilePictureURL;
          return user;
        }),
        builder: (BuildContext context, AsyncSnapshot<AppUser> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasData) {
            return _imageBuilder(recursiveCall: true);
          }
          return errorWidget;
        },
      );
    }
    widget.userWithImage.profilePictureURL = appUser.profilePictureURL;
    return _imageBuilder(recursiveCall: true);
  }


}
