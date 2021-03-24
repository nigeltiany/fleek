import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:gecies/gecies.dart';

RegExp _emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

class SignUpValidityResult {

  final bool usernameHasError;
  final String usernameError;

  final  bool emailHasError;
  final String emailError;

  final bool passwordHasError;
  final String passwordError;

  final bool hasAnError;

  SignUpValidityResult({
    @required this.usernameHasError,
    @required this.usernameError,
    @required this.emailHasError,
    @required this.emailError,
    @required this.passwordHasError,
    @required this.passwordError,
    @required this.hasAnError
  });

}

SignUpValidityResult hasValidityErrors({ @required String username, @required String email, @required String password }) {

  if (username == null) username = "";
  if (email == null) email = "";
  if (password == null) password = "";

  String usernameError;
  bool validUsername = username.isNotEmpty;
  bool userNameLongEnough = username.length >= 3;
  bool userNameShortEnough = username.length <= 12;
  bool userNameNotEmail = !_emailRegex.hasMatch(username);
  if(!validUsername) {
    usernameError = "Username cannot be empty";
  } else if (!userNameLongEnough) {
    usernameError = "Username must be 3 or more characters long";
  } else if (!userNameNotEmail) {
    usernameError = "Username cannot be an email address";
  } else if (!userNameShortEnough) {
    usernameError = "Username must less than 13 characters long";
  }

  String emailError;
  bool emailValid = _emailRegex.hasMatch(email);
  bool personalEmail = !email.endsWith(".edu") && !email.endsWith(".org");
  if (!emailValid) {
    emailError = "Invalid Email Address";
  } else if (!personalEmail) {
    emailError = "Please use your personal Email";
  }

  String passwordError;
  bool validPassword = password.isNotEmpty;
  bool validPasswordLength = password.length > 4;
  if(!validPassword) {
    passwordError = "Password cannot be empty";
  } else if (!validPasswordLength) {
    passwordError = "Password must 5 or more characters long";
  }

  return SignUpValidityResult(
    usernameHasError: usernameError != null,
    usernameError: usernameError,
    emailHasError: emailError != null,
    emailError: emailError,
    passwordHasError: passwordError != null,
    passwordError: passwordError,
    hasAnError: usernameError != null || emailError != null || passwordError != null
  );

}

Future<bool> signUp({
  @required BuildContext context, @required AppUser user,
  @required KeyPair keyPair, @required EncrypterState encrypter,
  @required String username, @required String email, @required String password }) async {

  if (hasValidityErrors(username: username, email: email, password: password).hasAnError) {
    return false;
  }

  showProgress(context, 'Creating new account...', false);

  try {

    UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password
    );

    HttpsCallable createKeyPair = FirebaseFunctions.instance.httpsCallable('createKeyPair');
    createKeyPair.call().then((result) {
      var snapshot = Map<String, String>.from(result.data);
      if (!snapshot.containsKey('PrivateKey') || !snapshot.containsKey('PublicKey')) {
        throw KeyException("Authentications keys response is deformed and unexpected");
      } else if (result.data['PublicKey'].toString().isEmpty || result.data['PrivateKey'].toString().isEmpty) {
        throw KeyException("Authentications keys received are deformed");
      }
      keyPair.publicKeyBase64 = result.data['PublicKey'];
      keyPair.privateKeyBase64 = result.data['PrivateKey'];
      encrypter.encrypter = (String message) async {
        return await Gecies.encrypt(result.data['PublicKey'], message);
      };
      user.publicKey = result.data['PublicKey'];
    }).catchError((e) {
      throw e;
    });

    await saveUserKeyPair(userID: result.user.uid, keyPair: keyPair);

    user.userID = result.user.uid;
    user.userName = username;
    if (kDebugMode) {
      user.developerAccount = true;
    }
    await FireStoreUtils.updateCurrentUser(user);

    Navigator.of(context).pop(); // Close Dialog
    // await goToNextScreenAfterAuth(context);
    return true;

  } catch (error) {
    Navigator.of(context).pop(); // Close Dialog
    if (error is FirebaseAuthException) {
      error.code != 'email-already-in-use'
        ? showAlertDialog(context, 'Failed', 'Couldn\'t sign up. ${error.code}')
        : showAlertDialog(context, 'Failed', 'Email already in use!');
    } else if (error is NoSuchMethodError) {
      print(error.stackTrace);
      print(error.hashCode);
      print(error.toString());
    } else if (error is FirebaseFunctionsException || error is KeyException) {
      showAlertDialog(context, 'Failed', 'An error occurred when creating your account');
      HttpsCallable panicDeleteUser = FirebaseFunctions.instance.httpsCallable('panicDeleteUser');
      await panicDeleteUser.call();
    } else {
      print(error.toString());
    }
    return false;
  }

}