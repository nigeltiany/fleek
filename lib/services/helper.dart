import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/constants.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import 'package:dating/model/ProfileSetup.dart';
import 'package:dating/model/StudentStatus.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/ui/StudentVerification/StudentVerification.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:dating/ui/profile_setup/ProfileSetupScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong/latlong.dart';
import 'package:location/location.dart';
import 'package:progress_dialog/progress_dialog.dart';

String validateName(String value) {
  String patttern = r'(^[a-zA-Z ]*$)';
  RegExp regExp = new RegExp(patttern);
  if (value.length == 0) {
    return "Name is Required";
  } else if (!regExp.hasMatch(value)) {
    return "Name must be a-z and A-Z";
  }
  return null;
}

String validateMobile(String value) {
  String patttern = r'(^[0-9]*$)';
  RegExp regExp = new RegExp(patttern);
  if (value.length == 0) {
    return "Mobile is Required";
  } else if (!regExp.hasMatch(value)) {
    return "Mobile Number must be digits";
  }
  return null;
}

String validatePassword(String value) {
  if (value.length < 6)
    return 'Password must be more than 5 charater';
  else
    return null;
}

String validateEmail(String value) {
  Pattern pattern =
      r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
  RegExp regex = new RegExp(pattern);
  if (!regex.hasMatch(value))
    return 'Enter Valid Email';
  else
    return null;
}

String validateConfirmPassword(String password, String confirmPassword) {
  if (password != confirmPassword) {
    return 'Password doesn\'t match';
  } else if (confirmPassword.length == 0) {
    return 'Confirm password is required';
  } else {
    return null;
  }
}

int getUserAge (Timestamp birthDate) {
  return ((DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(birthDate.millisecondsSinceEpoch)).inDays) / 365.25).floor();
}

//helper method to show progress
ProgressDialog progressDialog;

showProgress(BuildContext context, String message, bool isDismissible) async {
  progressDialog = ProgressDialog(context, type: ProgressDialogType.Normal, isDismissible: isDismissible);
  progressDialog.style(
    message: message,
    borderRadius: 10.0,
    backgroundColor: Color(COLOR_PRIMARY),
    progressWidget: Container(
      padding: EdgeInsets.all(8.0),
      child: CircularProgressIndicator(
        backgroundColor: Colors.white,
      ),
    ),
    elevation: 10.0,
    insetAnimCurve: Curves.easeInOut,
    messageTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 19.0,
      fontWeight: FontWeight.w600,
    ),
  );

  await progressDialog.show();
}

updateProgress(String message) {
  progressDialog?.update(message: message);
}

//helper method to show alert dialog
showAlertDialog(BuildContext context, String title, String content) {
  // set up the AlertDialog
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );
  AlertDialog alert = AlertDialog(
    title: Text(title,
      style: TextStyle(
        color: Color(COLOR_PRIMARY_DARK),
      ),
    ),
    content: Text(content),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

pushReplacement(BuildContext context, Widget destination) {
  Navigator.of(context).pushReplacement(
      new MaterialPageRoute(builder: (context) => destination));
}

push(BuildContext context, Widget destination) {
  Navigator.of(context)
      .push(new MaterialPageRoute(builder: (context) => destination));
}

pushAndRemoveUntil(BuildContext context, Widget destination, bool predict) {
  Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => destination),
          (Route<dynamic> route) => predict);
}

String formatTimestamp(int timestamp) {
  var format = new DateFormat('hh:mm a');
  var date = new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return format.format(date);
}

String setLastSeen(int seconds) {
  var format = DateFormat('hh:mm a');
  var date = new DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  var diff = DateTime.now().millisecondsSinceEpoch - (seconds * 1000);
  if (diff < 24 * HOUR_MILLIS) {
    return format.format(date);
  } else if (diff < 48 * HOUR_MILLIS) {
    return 'Yesterday at ${format.format(date)}';
  } else {
    format = DateFormat('MMM d');
    return '${format.format(date)}';
  }
}

Widget displayCircleImage(String picUrl, double size, hasBorder) =>
    CachedNetworkImage(
        imageBuilder: (context, imageProvider) =>
            _getCircularImageProvider(imageProvider, size, false),
        imageUrl: picUrl,
        placeholder: (context, url) =>
            _getPlaceholderOrErrorImage(size, hasBorder),
        errorWidget: (context, url, error) =>
            _getPlaceholderOrErrorImage(size, hasBorder));

Widget _getPlaceholderOrErrorImage(double size, hasBorder) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    color: const Color(0xff7c94b6),
    borderRadius: BorderRadius.all(Radius.circular(size / 2)),
    border: Border.all(
      color: Colors.white,
      width: hasBorder ? 2.0 : 0.0,
    ),
  ),
  child: ClipOval(
    child: Image.asset('assets/images/placeholder.jpg',
      fit: BoxFit.cover,
      height: size,
      width: size,
    ),
  ),
);

Widget _getCircularImageProvider(ImageProvider provider, double size, bool hasBorder) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: const Color(0xff7c94b6),
      borderRadius: new BorderRadius.all(new Radius.circular(size / 2)),
      border: new Border.all(
        color: Colors.white,
        width: hasBorder ? 2.0 : 0.0,
      ),
    ),
    child: ClipOval(
      child: FadeInImage(
        fit: BoxFit.cover,
        placeholder: Image.asset('assets/images/placeholder.jpg',
          fit: BoxFit.cover,
          height: size,
          width: size,
        ).image,
        image: provider,
      ),
    ),
  );
}

bool isDarkMode(BuildContext context) {
  if (Theme.of(context).brightness == Brightness.light) {
    return false;
  } else {
    return true;
  }
}

Future<LocationData> getCurrentLocation() async {
  Location location = Location();
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return null;
    }
  }
  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return null;
    }
  }
  return await location.getLocation();
}

double getDistance(UserLocation userLocation, UserLocation myLocation) {
  final Distance distance = new Distance();
  final double milesAway = distance.as(
    LengthUnit.Mile,
    LatLng(userLocation.latitude, userLocation.longitude),
    LatLng(myLocation.latitude, myLocation.longitude),
  );
  return milesAway;
}

skipNulls<Widget>(List<Widget> items) {
  return items..removeWhere((item) => item == null);
}

String audioMessageTime(Duration audioDuration) {
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitsHours(int n) {
    if (n >= 10) return "$n:";
    if (n == 0) return '';
    return "0$n:";
  }

  String twoDigitMinutes = twoDigits(audioDuration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(audioDuration.inSeconds.remainder(60));
  return "${twoDigitsHours(audioDuration.inHours)}$twoDigitMinutes:$twoDigitSeconds";
}

String updateTime(Timer timer) {
  Duration callDuration = Duration(seconds: timer.tick);
  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitsHours(int n) {
    if (n >= 10) return "$n:";
    if (n == 0) return '';
    return "0$n:";
  }

  String twoDigitMinutes = twoDigits(callDuration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(callDuration.inSeconds.remainder(60));
  return "${twoDigitsHours(callDuration.inHours)}$twoDigitMinutes:$twoDigitSeconds";
}

// IMPORTANT!!!
// NEVER CHANGE AFTER DEPLOYING. Should not be an alpha num character and neither of (_,-,/,\)
const String USER_ID_DELIMITER = ':';

String normalizedConversationID(String userID, String userID2) {
  if (userID.compareTo(userID2) < 0) {
    return "$userID$USER_ID_DELIMITER$userID2";
  } else {
    return "$userID2$USER_ID_DELIMITER$userID";
  }
}

Future<void> goToNextScreenAfterAuth (BuildContext context) async {
  var uid = FirebaseAuth.instance.currentUser.uid;
  // Save a reference to context variables because of the many async functions
  var contextUser = context.read<AppUser>();
  var keyPair = context.read<KeyPair>();
  var encrypterState = context.read<EncrypterState>();
  var verificationSnap = await FireStoreUtils.firestore.collection(VERIFICATIONS).doc(uid).get();

  if (verificationSnap.exists) {
    if (StudentStatus.fromJson(verificationSnap.data()).verified) {

      var profileSetupSnap = await FireStoreUtils.firestore.collection(USER_PROFILE_SETUP).doc(uid).get();

      if (profileSetupSnap.exists) {
        var onboardingStatus = ProfileSetupStatus.fromJson(profileSetupSnap.data());
        if (onboardingStatus.step == ProfileSetupStep.COMPLETE) {
          // GO TO HOME SCREEN
          _goToHomeScreen(context, contextUser, keyPair, encrypterState);
        } else {
          pushAndRemoveUntil(context, ProfileSetupScreen(step: onboardingStatus.step,), false);
        }
      } else {
        pushAndRemoveUntil(context, ProfileSetupScreen(step: ProfileSetupStep.NOT_STARTED,), false);
      }
    } else {
      pushAndRemoveUntil(context, StudentVerificationScreen(), false);
    }
  } else {
    pushAndRemoveUntil(context, StudentVerificationScreen(), false);
  }

}

_goToHomeScreen (BuildContext context, AppUser contextUser, KeyPair keyPair, EncrypterState encrypterState) async {

  DocumentSnapshot documentSnapshot = await FireStoreUtils.firestore.collection(USERS).doc(FirebaseAuth.instance.currentUser.uid).get();

  AppUser user;
  if (documentSnapshot != null && documentSnapshot.exists) {
    user = AppUser.fromJson(documentSnapshot.data());
    if (keyPair.privateKeyBase64 == null || keyPair.publicKeyBase64 == null) {
      KeyPair key = await getUserKeyPair(userID: user.userID);

      keyPair.publicKeyBase64 = key.publicKeyBase64;
      keyPair.privateKeyBase64 = key.privateKeyBase64;
    }

    encrypterState.encrypter = (String message) async {
      return await Gecies.encrypt(keyPair.publicKeyBase64, message);
    };
    user.online = true;
    user.signedIn = true;
    await FireStoreUtils.updateCurrentUser(user);
    contextUser.copy(user);
  }

  if (user == null) {
    showAlertDialog(context, 'Account', 'Unable to load account');
  } else {
    pushAndRemoveUntil(context, HomeScreen(), false);
  }

}

String privateKeyLocation({@required String userID}) {
  return "private-key::$userID";
}
String publicKeyLocation({@required String userID}) {
  return "public-key::$userID";
}

Future<KeyPair> getUserKeyPair({ @required String userID }) async {

  KeyPair keyPair = KeyPair();
  FlutterSecureStorage secureStorage = FlutterSecureStorage();
  String privateKey = await secureStorage.read(
    key: privateKeyLocation(userID: userID)
  );
  String publicKey = await secureStorage.read(
    key: publicKeyLocation(userID: userID)
  );

  if (publicKey == null || privateKey == null) {

    HttpsCallable getKeyPair = FirebaseFunctions.instance.httpsCallable('getKeyPair');

    await getKeyPair.call().then((result) async {

      if (result.data['PrivateKey'] == null || result.data['PrivateKey'] == null) {
        throw KeyException("Authentications keys response is deformed and unexpected");
      }

      keyPair.publicKeyBase64 = result.data['PublicKey'];
      keyPair.privateKeyBase64 = result.data['PrivateKey'];

      await saveUserKeyPair(userID: userID, keyPair: keyPair);

    }).catchError((e) {
      throw FirebaseFunctionsException(message: e.toString());
    });

  } else {
    keyPair.privateKeyBase64 = privateKey;
    keyPair.publicKeyBase64 = publicKey;
  }

  return keyPair;
}

saveUserKeyPair ({ @required String userID, @required KeyPair keyPair }) async {
  FlutterSecureStorage secureStorage = FlutterSecureStorage();
  await secureStorage.write(key: privateKeyLocation(userID: userID), value: keyPair.privateKeyBase64).catchError((e) => print("here 1"));
  await secureStorage.write(key: publicKeyLocation(userID: userID), value: keyPair.publicKeyBase64).catchError((e) => print("here 2"));
}