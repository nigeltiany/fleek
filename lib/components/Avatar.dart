import 'package:dating/model/HomeConversationModel.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {

  final HomeConversationModel homeConversationModel;

  Avatar(this.homeConversationModel);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        push(context, UserDetailsScreen(user: homeConversationModel.members.first, isMatch: true,));
      },
      child: Stack(
        alignment: Alignment.bottomRight,
        children: <Widget>[
          displayCircleImage(homeConversationModel.members.first.profilePictureURL, 50, false),
          Positioned(
            right: 2.4,
            bottom: 2.4,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: homeConversationModel.members.first.active ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: isDarkMode(context) ? Color(0xFF303030) : Colors.white,
                  width: 1.6,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

}
