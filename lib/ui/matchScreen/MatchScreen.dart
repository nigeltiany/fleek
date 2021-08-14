import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/components/UserImage.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:provider/provider.dart';

class MatchScreen extends StatefulWidget {

  MatchScreen({
    Key key,
  }) : super(key: key);

  @override
  _MatchScreenState createState() => _MatchScreenState();

}

class _MatchScreenState extends State<MatchScreen> {

  bool checkingConversationState = false;

  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
    super.dispose();
  }

  SwiperPagination _getPagination(int count) {
    return SwiperPagination(
      alignment: Alignment.centerRight,
      builder: count <= 9 ? SwiperPagination.fraction : SwiperPagination.dots,
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    return Material(
      child: Consumer<MatchData>(
        builder: (BuildContext context, MatchData matchData, _) {
          List<FleekMatch> unseenMatches = matchData.matches.where((m) => m.seen == false).toList();
          return Swiper(
            loop: true,
            autoplay: false,
            scrollDirection: Axis.vertical,
            itemCount: unseenMatches.length,
            pagination: unseenMatches.length > 1 ? _getPagination(unseenMatches.length) : null,
            physics: unseenMatches.length > 1 ? AlwaysScrollableScrollPhysics() : NeverScrollableScrollPhysics(),
            itemBuilder: (BuildContext context, int index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  UserImage(userWithImage: unseenMatches[index].match),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0),
                    child: Column(
                      verticalDirection: VerticalDirection.up,
                      children: <Widget>[
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                            child: SecondaryButton(
                              label: 'KEEP SWIPING',
                              onTap: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: PrimaryButton.icon(
                                    icon: Icon(Icons.person),
                                    onTap: () {
                                      pushReplacement(context,
                                        UserDetailsScreen(
                                          identifiableUser: unseenMatches[index].match,
                                          isMatch: true,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                SizedBox(width: 32),
                                Expanded(
                                  child: PrimaryButton.icon(
                                    icon: Icon(Icons.forum),
                                    onTap: () {
                                      pushReplacement(context,
                                        ChatScreen(
                                          identifiableUser: unseenMatches[index].match,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}
