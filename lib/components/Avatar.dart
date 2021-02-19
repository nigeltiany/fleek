import 'package:dating/model/Swipe.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {

  final IdentifiableUser identifiableUser;

  Avatar(this.identifiableUser);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        push(context, UserDetailsScreen(identifiableUser: identifiableUser, isMatch: true,));
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          displayCircleImage((identifiableUser is AppUser) ? (identifiableUser as AppUser).profilePictureURL : (identifiableUser as SwipeSubject).profilePictureURL, 50, false),
          // Positioned(
          //   right: 2.4,
          //   bottom: 2.4,
          //   child: Container(
          //     width: 12,
          //     height: 12,
          //     decoration: BoxDecoration(
          //       color: homeConversationModel.members.first.active ? Colors.green : Colors.grey,
          //       borderRadius: BorderRadius.circular(100),
          //       border: Border.all(
          //         color: isDarkMode(context) ? Color(0xFF303030) : Colors.white,
          //         width: 1.6,
          //       ),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }

}
