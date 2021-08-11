import 'package:dating/constants.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/LikeData.dart';
import 'package:dating/ui/likes/likes_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LikesButton extends StatefulWidget {
  
  const LikesButton({ Key key }) : super(key: key);

  @override
  _LikesButtonState createState() => _LikesButtonState();

}

class _LikesButtonState extends State<LikesButton> {

  @override
  Widget build(BuildContext context) {
    return Consumer<LikeData>(
      builder: (BuildContext context, LikeData likeData, _) {
        List<Swipe> unseenLikes = likeData.likes.where((m) => m.hasBeenSeen == false).toList();
        return Stack(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.favorite,
                color: unseenLikes.length > 0 ? Color(COLOR_PRIMARY) : Colors.grey,
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LikesPage()
                  ),
                );
              },
            ),
            unseenLikes.length > 0 ? Positioned(
              right: 16,
              top: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
                    width: 1.6,
                  ),
                ),
              ),
            ) : Container(),
          ],
        );
      }
    );
  }

}
