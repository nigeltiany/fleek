import 'dart:io';

import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/FormInput.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:dating/ui/terms/terms.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecies/gecies.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../constants.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State createState() => _SignUpState();
}

class _SignUpState extends State<SignUpScreen> {

  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _emailController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  GlobalKey<ScaffoldState> _scaffoldState = GlobalKey();


  String username, email, mobile, password;
  String usernameError, emailError, passwordError;
  LocationData signUpLocation;
  bool termsPopUpShown = false;

  Future<bool> hasAcceptedTermsAndConditions(BuildContext ctx) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return (prefs.getBool(TERMS_ACCEPTED) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return FutureBuilder<bool>(
        future: hasAcceptedTermsAndConditions(context),
        builder: (BuildContext ctx, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
              ),
            );
          } else if (snapshot.data == false && !termsPopUpShown) {
            Future.delayed(Duration.zero, () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext context) {
                  return TermsScreen();
                },
              ).then((_) {
                termsPopUpShown = true;
                setState(() {});
              });
            });
            return _termsErrorWidget;
          } else {
            if (snapshot.data) {
              return signUpScreen();
            }
            Future.delayed(Duration.zero, () => pushReplacement(context, AuthScreen()));
            return _termsErrorWidget;
          }
        },
      );
    }
    return signUpScreen();
  }

  Widget get _termsErrorWidget {
    return FutureBuilder(
      future: Future.delayed(Duration(seconds: 10)),
      builder: (BuildContext context, _) {
        return SafeArea(
          child: Container(
            child: Center(
              child: Text("An unexpected error occurred. Terms not accepted. Close app and try again",
                style: TextStyle(
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Scaffold signUpScreen () {
    return Scaffold(
      key: _scaffoldState,
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        elevation: 0.0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.white : Colors.black
        ),
        centerTitle: true,
        title: Image.asset('assets/images/app_logo.png',
          width: 42.0,
          height: 42.0,
          fit: BoxFit.cover,
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(left: 16.0, right: 16, bottom: 16),
          child: formUI(),
        ),
      ),
    );
  }

  Widget formUI() {
    return new Column(
      children: <Widget>[
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(top: 32.0, left: 24.0),
            child: Text('Create an Account',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        FormInput(
          type: TextInputType.name,
          textInputAction: TextInputAction.next,
          controller: _usernameController,
          label: "Creative username",
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        _showError(usernameError),
        FormInput(
          type: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          controller: _emailController,
          label: "Personal Email",
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        _showError(emailError),
        FormInput(
          type: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          controller: _passwordController,
          label: "Password",
          obscureText: true,
          onSubmitted: (password) => _signUp(),
        ),
        _showError(passwordError),
        SizedBox(height: 32,),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0, left: 24.0),
            child: PrimaryButton(
              label: "SIGN UP",
              onTap: _signUp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _showError (String errorString) {
    if (errorString != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          child: Text(errorString, style: TextStyle(color: Colors.redAccent)),
        ),
      );
    }
    return Container();
  }

  bool _hasValidityErrors() {

    RegExp emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");

    bool validUsername = _usernameController.value.text.trim().isNotEmpty;
    bool userNameLongEnough = _usernameController.value.text.length >= 3;
    bool userNameShortEnough = _usernameController.value.text.length <= 12;
    bool userNameNotEmail = !emailRegex.hasMatch(_usernameController.value.text);
    if(!validUsername) {
      usernameError = "Username cannot be empty";
    } else if (!userNameLongEnough) {
      usernameError = "Username must be 3 or more characters long";
    } else if (!userNameNotEmail) {
      usernameError = "Username cannot be an email address";
    } else if (!userNameShortEnough) {
      usernameError = "Username must less than 13 characters long";
    } else {
      usernameError = null;
    }

    bool emailValid = emailRegex.hasMatch(_emailController.value.text);
    bool personalEmail = !_emailController.value.text.endsWith(".edu") && !_emailController.value.text.endsWith(".org");
    if (!emailValid) {
      emailError = "Invalid Email Address";
    } else if (!personalEmail) {
      emailError = "Please use your personal Email";
    } else {
      emailError = null;
    }

    bool validPassword = _usernameController.value.text.trim().isNotEmpty;
    bool validPasswordLength = _passwordController.value.text.trim().length > 4;
    if(!validPassword) {
      passwordError = "Password cannot be empty";
    } else if (!validPasswordLength) {
      passwordError = "Password must 5 or more characters long";
    } else {
      passwordError = null;
    }

    setState(() {});
    return !validUsername || !userNameLongEnough || !userNameShortEnough || !userNameNotEmail || !emailValid || !personalEmail || !validPassword || !validPasswordLength;

  }

  _signUp() async {

    if (_hasValidityErrors()) {
      return;
    }

    showProgress(context, 'Creating new account...', false);

    try {

      UserCredential result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.value.text.trim(),
        password: _passwordController.value.text.trim()
      );

      // Save a reference to context variables because of the many async functions
      var user = context.read<AppUser>();
      var keyPair = context.read<KeyPair>();
      var encrypter = context.read<EncrypterState>();

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

      await saveUserKeyPair(userID: result.user.uid, keyPair: context.read<KeyPair>());

      user.userID = result.user.uid;
      user.userName = _usernameController.text.trim();
      if (kDebugMode) {
        user.developerAccount = true;
      }
      await FireStoreUtils.updateCurrentUser(user);

      Navigator.of(context).pop(); // Close Dialog
      await goToNextScreenAfterAuth(context);

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
    }

  }

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(TERMS_ACCEPTED, false));
    super.dispose();
  }

}