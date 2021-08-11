import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
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

  Widget _imageBuilder(Swipe like) {
    return GestureDetector(
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => UserDetailsScreen(
              identifiableUser: like.subject,
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
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: like.subject.profilePictureURL,
            placeholder: (context, imageUrl) {
              return Icon(
                Icons.hourglass_empty,
                size: 75,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              );
            },
            errorWidget: (context, imageUrl, error) {
              return Icon(
                Icons.error_outline,
                size: 75,
                color: isDarkMode(context) ? Colors.black : Colors.white,
              );
            },
          ),
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

}
