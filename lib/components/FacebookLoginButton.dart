import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/main.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:http/http.dart' as http;

class FacebookLoginButton extends StatefulWidget {

  @override
  _FacebookLoginButtonState createState() => _FacebookLoginButtonState();
}

class _FacebookLoginButtonState extends State<FacebookLoginButton> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: double.infinity),
      child: RaisedButton.icon(
        label: Text('Facebook Login',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode(context) ? Colors.black : Colors.white,
          ),
        ),
        icon: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Image.asset(
            'assets/images/facebook_logo.png',
            color: isDarkMode(context) ? Colors.black : Colors.white,
            height: 30,
            width: 30,
          ),
        ),
        color: Color(FACEBOOK_BUTTON_COLOR),
        textColor: Colors.white,
        splashColor: Color(FACEBOOK_BUTTON_COLOR),
        onPressed: () async {
          final facebookLogin = FacebookLogin();
          final result = await facebookLogin.logIn(['email']);
          switch (result.status) {
            case FacebookLoginStatus.loggedIn:
              showProgress(context, 'Logging in, please wait...', false);
              await
              FirebaseAuth.instance.signInWithCredential(
                FacebookAuthProvider.credential(result.accessToken.token)
              ).then((UserCredential authResult) async {
                AppUser user = await FireStoreUtils().getCurrentUser(authResult.user.uid);
                if (user == null) {
                  _createUserFromFacebookLogin(result, authResult.user.uid);
                } else {
                  _syncUserDataWithFacebookData(result, user);
                }
              });
              break;

            case FacebookLoginStatus.cancelledByUser:
              break;
            case FacebookLoginStatus.error:
              showAlertDialog(context, 'Error', 'Couldn\'t login via facebook.');
              break;
          }
        },
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
            side: BorderSide(color: Color(FACEBOOK_BUTTON_COLOR))),
      ),
    );
  }

  void _createUserFromFacebookLogin(
      FacebookLoginResult result, String userID) async {
    final token = result.accessToken.token;
    final graphResponse = await http.get('https://graph.facebook.com/v2'
        '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    final profile = json.decode(graphResponse.body);
    // AppUser user = AppUser(
    //     firstName: profile['first_name'],
    //     lastName: profile['last_name'],
    //     email: profile['email'],
    //     profilePictureURL: profile['picture']['data']['url'],
    //     active: true,
    //     fcmToken: await FireStoreUtils.firebaseMessaging.getToken(),
    //     photos: [],
    //     age: '',
    //     bio: '',
    //     lastOnlineTimestamp: Timestamp.now(),
    //     school: '',
    //     // settings: Settings(
    //     //   distanceRadius: 10,
    //     //   gender: Gender.MALE,
    //     //   genderPreference: GenderPreference.FEMALE,
    //     //   pushNewMatchesEnabled: true,
    //     //   pushNewMessages: true,
    //     //   pushSuperLikesEnabled: true,
    //     //   pushTopPicksEnabled: true,
    //     //   showMe: true,
    //     // ),
    //     showMe: true,
    //     signUpLocation: UserLocation(latitude: 0.1, longitude: 0.1),
    //     location: UserLocation(latitude: 0.1, longitude: 0.1),
    //     userID: userID);
    // await FireStoreUtils.firestore
    //     .collection(USERS)
    //     .doc(userID)
    //     .set(user.toJson())
    //     .then((onValue) {
    //   MyAppState.currentUser = null;
    //   MyAppState.currentUser = user;
    //   Navigator.of(context).pop(); // Close Dialog
    //   pushAndRemoveUntil(context, HomeScreen(user: user), false);
    // });
  }

  void _syncUserDataWithFacebookData(FacebookLoginResult result,
      AppUser user) async {
    // final token = result.accessToken.token;
    // final graphResponse = await http.get('https://graph.facebook.com/v2'
    //     '.12/me?fields=name,first_name,last_name,email,picture.type(large)&access_token=$token');
    // final profile = json.decode(graphResponse.body);
    // user.profilePictureURL = profile['picture']['data']['url'];
    // user.firstName = profile['first_name'];
    // user.lastName = profile['last_name'];
    // user.email = profile['email'];
    // user.active = true;
    // user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
    // await FireStoreUtils.updateCurrentUser(user);
    // MyAppState.currentUser = user;
    // Navigator.of(context).pop(); // Close Dialog
    // pushAndRemoveUntil(context, HomeScreen(user: user), false);
  }
}
