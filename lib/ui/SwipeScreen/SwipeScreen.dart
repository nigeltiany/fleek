import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating/CustomFlutterTinderCard.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/ui/matchScreen/MatchScreen.dart';
import 'package:dating/ui/upgradeAccount/UpgradeAccount.dart';
import 'package:dating/ui/userDetailsScreen/UserDetailsScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class SwipeScreen extends StatefulWidget {

  const SwipeScreen({
    Key key,
  }) : super(key: key);

  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {

  final FireStoreUtils _fireStoreUtils = FireStoreUtils();
  CardController cardController;
  AppUser currentUser;
  FleekData fleekData;

  _SwipeScreenState();

  @override
  void initState() {
    super.initState();
    currentUser = context.read<AppUser>();
    fleekData = context.read<FleekData>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!currentUser.settings.showMe) {
      return Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.public_off, size: 72,),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
            child: Text("Your profile is hidden. Turn on visibility to see other users"),
          ),
          SizedBox(height: 32,),
          Padding(
            padding: const EdgeInsets.only(right: 40.0, left: 40.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity),
              child: SecondaryButton(
                label: "Turn on",
                onTap: () async {
                  currentUser.settings.showMe = true;
                  await FireStoreUtils.updateCurrentUser(currentUser);
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      );
    }
    return Consumer<FleekData>(
      builder: (BuildContext context, FleekData data, _) {
        if (data.fetchingData && data.users.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(COLOR_ACCENT)),
            ),
          );
        } else if (!data.fetchingData && data.users.isEmpty) {
          return Container(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Sorry, there is no one else to show you :-(',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        } else {
          return _asyncCards(context);
        }
      }
    );
  }

  Widget _buildCard(AppUser fleekUser) {
    return GestureDetector(
      onTap: () async {
        _launchDetailsScreen(fleekUser);
      },
      child: Card(
        child: Stack(
          children: <Widget>[
            Container(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: CachedNetworkImage(
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    imageUrl: fleekUser.profilePictureURL == DEFAULT_AVATAR_URL ? '' : fleekUser.profilePictureURL,
                    placeholder: (context, imageUrl) {
                      return Icon(
                        Icons.account_circle,
                        size: MediaQuery.of(context).size.width * .8,
                        color: isDarkMode(context) ? Colors.black : Colors.white,
                      );
                    },
                    errorWidget: (context, imageUrl, error) {
                      return Icon(
                        Icons.account_circle,
                        size: MediaQuery.of(context).size.width * .8,
                        color: isDarkMode(context) ? Colors.black : Colors.white,
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              right: 5,
              child: IconButton(
                icon: Icon(Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
                iconSize: 30,
                onPressed: () => _onCardSettingsClick(fleekUser),
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: Visibility(
                visible: fleekData.previousLeftSwipedUser != null,
                child: FloatingActionButton(
                  heroTag: '${fleekUser.userID}',
                  backgroundColor: Color(COLOR_PRIMARY),
                  mini: true,
                  child: Icon(
                    Icons.undo,
                    color: Colors.white,
                  ),
                  onPressed: () => _undo(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                verticalDirection: VerticalDirection.down,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(fleekUser.birthDate == null ? '${fleekUser.userName}' : '${fleekUser.userName}, ${getUserAge(fleekUser.birthDate)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  // Row(
                  //   children: <Widget>[
                  //     Icon(
                  //       Icons.school,
                  //       color: Colors.white,
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.only(left: 8.0),
                  //       child: Text(
                  //         '${fleekUser.school}',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // Row(
                  //   children: <Widget>[
                  //     Icon(
                  //       Icons.location_on,
                  //       color: Colors.white,
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.only(left: 8.0),
                  //       child: Text(
                  //         '${fleekUser.milesAway}',
                  //         style: TextStyle(
                  //           color: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            )
          ],
        ),
        shape: RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.circular(25),
        ),
        color: Color(COLOR_PRIMARY),
      ),
    );
  }

  Future<void> _launchDetailsScreen(AppUser fleekUser) async {
    CardSwipeOrientation result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDetailsScreen(
          identifiableUser: fleekUser,
          isMatch: false,
        ),
      ),
    );
    if (result != null) {
      if (result == CardSwipeOrientation.LEFT) {
        cardController.triggerLeft();
      } else {
        cardController.triggerRight();
      }
    }
  }

  _onCardSettingsClick(AppUser user) {
    final action = CupertinoActionSheet(
      message: Text(
        user.userName,
        style: TextStyle(fontSize: 15.0),
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Block user"),
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'Blocking user...', false);
            bool isSuccessful = await _fireStoreUtils.blockUser(user, 'block');
            Navigator.of(context).pop(); // Close Dialog
            if (isSuccessful) {
              await _fireStoreUtils.onSwipeLeft(currentUser: currentUser, dislikedUser: user);
              fleekData.removeUser(user, currentUser.settings.searchInterest);
              Scaffold.of(context).showSnackBar(SnackBar(content: Text
                ('${user.userName} has been blocked.'),),);
            } else {
              Scaffold.of(context).showSnackBar(SnackBar(content: Text
                ('Couldn\'t block ${user.userName}, please try again later.'),),);
            }
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Report user"),
          onPressed: () async {
            Navigator.pop(context);
            showProgress(context, 'Reporting user...', false);
            bool isSuccessful = await _fireStoreUtils.blockUser(
                user, 'report');
            Navigator.of(context).pop(); // Close Dialog
            if (isSuccessful) {
              await _fireStoreUtils.onSwipeLeft(currentUser: currentUser, dislikedUser: user);
              fleekData.removeUser(user, currentUser.settings.searchInterest);
              Scaffold.of(context).showSnackBar(SnackBar(content: Text
                ('${user.userName} has been reported and blocked.'),),);
            } else {
              Scaffold.of(context).showSnackBar(SnackBar(content: Text
                ('Couldn\'t report ${user.userName}, please try again later.'),),);
            }
          },
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text(
          "Cancel",
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (context) => action);
  }

  _undo() async {
    //if (currentUser.isVip != null && currentUser.isVip) {
    //   AppUser undoUser = swipedUsers.removeLast();
    //   users.insert(0, undoUser);
    //   _fireStoreUtils.updateCardStream(users);
    //   await _fireStoreUtils.undo(undoUser);
         fleekData.undoLeftSwipe(currentUser.settings.searchInterest);
    // } else {
    //   _showUpgradeAccountDialog();
    // }
  }

  Widget _asyncCards(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.9,
                width: MediaQuery.of(context).size.width,
                child: TinderSwapCard(
                  animDuration: 300,
                  orientation: AmassOrientation.BOTTOM,
                  totalNum: fleekData.users.length,
                  stackNum: 3,
                  swipeEdge: 12,
                  maxWidth: MediaQuery.of(context).size.width,
                  maxHeight: MediaQuery.of(context).size.height,
                  minWidth: MediaQuery.of(context).size.width * 0.9,
                  minHeight: MediaQuery.of(context).size.height * 0.9,
                  cardBuilder: (context, index) => _buildCard(fleekData.users[index]),
                  cardController: cardController = CardController(),
                  swipeCompleteCallback: (CardSwipeOrientation orientation, int index) async {
                    // if (orientation == CardSwipeOrientation.LEFT || orientation == CardSwipeOrientation.RIGHT) {
                      // bool isValidSwipe = currentUser.isVip != null && currentUser.isVip ? true :
                      AppUser swipedUser = fleekData.users.elementAt(index);
                      await _fireStoreUtils.incrementSwipe();
                      if (orientation == CardSwipeOrientation.RIGHT) {
                        await FireStoreUtils.onSwipeRight(currentUser: currentUser, likedUser: swipedUser);
                        fleekData.removeUser(fleekData.users.elementAt(index), currentUser.settings.searchInterest);
                      } else if (orientation == CardSwipeOrientation.LEFT) {
                        fleekData.previousLeftSwipedUser = fleekData.users.elementAt(index);
                        await _fireStoreUtils.onSwipeLeft(currentUser: currentUser, dislikedUser: swipedUser);
                        fleekData.removeUser(fleekData.users.elementAt(index), currentUser.settings.searchInterest);
                      }
                      if (fleekData.users.length < 5 && fleekData.recentlyFetchedCount >= FleekData.MAX_FETCH_COUNT) {
                        fleekData.loadData(currentUser);
                      }
                    // }
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(
                elevation: 1,
                heroTag: 'left',
                onPressed: () {
                  cardController.triggerLeft();
                },
                backgroundColor: Colors.white,
                mini: false,
                child: Icon(Icons.close,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              FloatingActionButton(
                elevation: 1,
                heroTag: 'center',
                onPressed: () {
                  cardController.triggerRight();
                },
                backgroundColor: Color(COLOR_PRIMARY),
                mini: true,
                child: Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              FloatingActionButton(
                elevation: 1,
                heroTag: 'right',
                onPressed: () {
                  cardController.triggerRight();
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
      ],
    );
  }

  void _showUpgradeAccountDialog() {

    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    Widget upgradeButton = FlatButton(
      child: Text("Upgrade Now"),
      onPressed: () {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          builder: (context) {
            return UpgradeAccount();
          },
        );
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text('Upgrade account'),
      content: Text('Upgrade your account now to have unlimited swipes per day.'),
      actions: [upgradeButton, okButton],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );

  }
  
}