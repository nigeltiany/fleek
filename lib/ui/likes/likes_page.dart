import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/UserImage.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/LikeData.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LikesPage extends StatefulWidget {

  const LikesPage({Key key}) : super(key: key);

  @override
  _LikesPageState createState() => _LikesPageState();

}

class _LikesPageState extends State<LikesPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Likes",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: _buildGridView(),
        ),
      ),
    );
  }

  Widget _imageBuilder(Swipe like, { bool recursiveCall = false }) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDetailsScreen(
              identifiableUser: like.swiper,
              isMatch: false,
            ),
          ),
        );
        if (!like.hasBeenSeen) {
          await FireStoreUtils.updateLikeAsSeen(like);
          setState(() {
            like.hasBeenSeen = true;
          });
        }
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: like.hasBeenSeen ? BorderSide.none : BorderSide(
            color: Color(COLOR_PRIMARY),
            width: 4,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        color: Color(COLOR_PRIMARY),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: UserImage(userWithImage: like.swiper),
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return Consumer<LikeData>(
      builder: (BuildContext context, LikeData likeData, _) {
        return GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.only(right: 16, left: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _imageBuilder(likeData.likes[index]),
          itemCount: likeData.likes.length,
          physics: BouncingScrollPhysics(),
        );
      },
    );
  }

  // Widget profileSource (Swipe like, Widget errorWidget) {
  //   var likedUser = Provider.of<ConversationData>(context, listen: false).getUser(like.swiper.userID);
  //   if (likedUser == null) {
  //     return FutureBuilder<AppUser>(
  //       future: FireStoreUtils.getUserByID(like.swiper.userID).then((user) {
  //         Provider.of<ConversationData>(context, listen: false).addConversationUser(user);
  //         like.swiper = SwipeSubject.fromUser(user);
  //         return user;
  //       }),
  //       builder: (BuildContext context, AsyncSnapshot<AppUser> snapshot) {
  //         if (snapshot.connectionState == ConnectionState.waiting) {
  //           return CircularProgressIndicator();
  //         } else if (snapshot.hasData) {
  //           return _imageBuilder(like, recursiveCall: true);
  //         }
  //         return errorWidget;
  //       },
  //     );
  //   }
  //   like.swiper = SwipeSubject.fromUser(likedUser);
  //   return _imageBuilder(like, recursiveCall: true);
  // }

}
