import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/components/ButtonType.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/ui/fullScreenImageViewer/FullScreenImageViewer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../CustomFlutterTinderCard.dart';
import '../../constants.dart';

class UserDetailsScreen extends StatefulWidget {

  final IdentifiableUser identifiableUser;
  final bool isMatch;

  const UserDetailsScreen({Key key, this.identifiableUser, this.isMatch}) : super(key: key);

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState(identifiableUser);
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {

  final IdentifiableUser identifiableUser;
  AppUser appUser;
  List<String> images = [];

  _UserDetailsScreenState(this.identifiableUser);

  List _pages = [];
  PageController controller = PageController(
    initialPage: 0,
  );
  PageController gridPageViewController = PageController(
    initialPage: 0,
  );
  List<Widget> _gridPages = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: isDarkMode(context) ? Colors.black : Colors.white,
      ),
    );

    if (identifiableUser is AppUser) {

      appUser = identifiableUser;

    } else if (appUser == null) {

      appUser = Provider.of<ConversationData>(context, listen: false).getUser(identifiableUser.userID);

      if (appUser == null) {

        return FutureBuilder<AppUser>(
          future: FireStoreUtils.getUserByID(identifiableUser.userID).then((user) {
            Provider.of<ConversationData>(context, listen: false).addConversationUser(user);
            appUser = user;
            return user;
          }),
          builder: (BuildContext context, AsyncSnapshot<AppUser> snapshot) {
            if (snapshot.hasData) {
              return _mainContent;
            }
            return Container(
              child: Center(
                child: snapshot.hasError ? Icon(Icons.error, color: Colors.redAccent) : CircularProgressIndicator(),
              ),
            );
          },
        );

      }

    }

    return _mainContent;

  }

  Widget get _mainContent {

    images.removeWhere((url) => url == appUser.profilePictureURL);
    images.add(appUser.profilePictureURL);
    appUser.photos.cast<String>().forEach((String url) {
      if (!images.contains(url)) {
        images.add(url);
      }
    });
    images.removeWhere((element) => element == null);

    num imageViewerHeight = (MediaQuery.of(context).size.height * 0.6) + 28;
    _gridPages = _buildGridView();

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Stack(
                alignment: Alignment.bottomRight,
                clipBehavior: Clip.none,
                children: <Widget>[
                  Container(
                    height: imageViewerHeight,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Container(
                          height: imageViewerHeight - 28,
                          child: PageView.builder(
                            itemBuilder: (BuildContext context, int index) => _buildImage(index),
                            itemCount: images.length,
                            controller: controller,
                            scrollDirection: Axis.horizontal,
                          ),
                        ),
                        Container(
                          color: Colors.transparent,
                          height: 28,
                        )
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SmoothPageIndicator(
                        controller: controller, // PageController
                        count: images.length,
                        effect: SlideEffect(
                          spacing: 4.0,
                          radius: 4.0,
                          dotWidth: (MediaQuery.of(context).size.width - (4 * images.length) - 4) / images.length,
                          dotHeight: 4.0,
                          paintStyle: PaintingStyle.fill,
                          dotColor: Colors.grey,
                          activeDotColor: Colors.white,
                        ), // your preferred effect
                      ),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 0,
                    child: FloatingActionButton(
                      backgroundColor: Color(COLOR_PRIMARY),
                      child: Icon(!widget.isMatch ? Icons.chevron_left : Icons.close,
                        size: 32,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: Row(
                  children: <Widget>[
                    Text('${appUser.userName}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 27,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(appUser.birthDate == null ? '' : '${getUserAge(appUser.birthDate)}',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //   child: Row(
              //     children: <Widget>[
              //       Icon(Icons.school),
              //       Text('   ${user.school}')
              //     ],
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 16.0, top: 8),
              //   child: Row(
              //     children: <Widget>[
              //       Icon(Icons.location_on),
              //       Text('   ${user.milesAway}')
              //     ],
              //   ),
              // ),
              // Divider(),
              Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 8),
                child: Text(appUser.bio ?? ""),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 16, right: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: skipNulls([
                    Text(
                      'Photos',
                      textAlign: TextAlign.start,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    (_pages.length >= 2 ? SmoothPageIndicator(
                      controller: gridPageViewController,
                      count: _pages.length,
                      effect: JumpingDotEffect(
                        spacing: 4.0,
                        radius: 4.0,
                        dotWidth: 8,
                        dotHeight: 8.0,
                        paintStyle: PaintingStyle.fill,
                        dotColor: Colors.grey, activeDotColor: Color(COLOR_PRIMARY)
                      ), // your preferred effect
                    ) : null),
                  ]),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: 16,
                  bottom: widget.isMatch ? 8 : 112,
                ),
                child: SizedBox(
                  height: appUser.photos.length > 3 ? 260 : 130,
                  width: double.infinity,
                  child: PageView(
                    controller: gridPageViewController,
                    children: _gridPages,
                  ),
                ),
              ),
              Visibility(
                visible: widget.isMatch,
                child: Padding(
                  padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: double.infinity),
                    child: SecondaryButton(
                      label: "UN-MATCH",
                      buttonType: ButtonType.DANGER,
                      onTap: () async {
                        await FireStoreUtils.removeMatch(identifiableUser).catchError((e) => print(e));
                        var cid = normalizedConversationID(FirebaseAuth.instance.currentUser.uid, identifiableUser.userID);
                        Provider.of<ConversationData>(context, listen: false).removeConversation(cid);
                        Provider.of<MatchData>(context, listen: false).removeCachedMatch(identifiableUser);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
        bottomSheet: Visibility(
          visible: !widget.isMatch,
          child: Container(
            height: 100,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FloatingActionButton(
                    elevation: 4,
                    heroTag: 'left',
                    onPressed: () {
                      Navigator.pop(context, CardSwipeOrientation.LEFT);
                    },
                    backgroundColor: Colors.white,
                    mini: false,
                    child: Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                  FloatingActionButton(
                    elevation: 4,
                    heroTag: 'center',
                    onPressed: () {
                      Navigator.pop(context, CardSwipeOrientation.RIGHT);
                    },
                    backgroundColor: Colors.white,
                    mini: true,
                    child: Icon(
                      Icons.star,
                      color: Color(COLOR_PRIMARY),
                      size: 30,
                    ),
                  ),
                  FloatingActionButton(
                    elevation: 4,
                    heroTag: 'right',
                    onPressed: () {
                      Navigator.pop(context, CardSwipeOrientation.RIGHT);
                    },
                    backgroundColor: Colors.white,
                    mini: false,
                    child: Icon(
                      Icons.favorite,
                      color: Colors.redAccent,
                      size: 40,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

  }

  List<Widget> _buildGridView() {
    
    _pages.clear();
    
    List<Widget> gridViewPages = [];
    var len = images.length;
    var size = 6;
    for (var i = 0; i < len; i += size) {
      var end = (i + size < len) ? i + size : len;
      _pages.add(images.sublist(i, end));
    }
    
    _pages.forEach((elements) {
      gridViewPages.add(
        GridView.builder(
          padding: EdgeInsets.only(right: 16, left: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) => _imageBuilder(elements[index]),
          itemCount: elements.length,
          physics: BouncingScrollPhysics(),
        ),
      );
    });
    
    return gridViewPages;
    
  }

  Widget _imageBuilder(String url) {
    return GestureDetector(
      onTap: () {
        push(context, FullScreenImageViewer(image: NetworkImage(url), tag: url));
      },
      child: Card(
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        color: Color(COLOR_PRIMARY),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            fit: BoxFit.cover,
            imageUrl: appUser.profilePictureURL == DEFAULT_AVATAR_URL ? '' : url,
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

  Widget _buildImage(int index) {
    return CachedNetworkImage(
      fit: BoxFit.cover,
      imageUrl: appUser.profilePictureURL == DEFAULT_AVATAR_URL ? '' : images[index],
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
    );
  }

  @override
  void dispose() {
    gridPageViewController.dispose();
    controller.dispose();
    super.dispose();
  }
  
}
