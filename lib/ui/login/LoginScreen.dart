import 'package:cloud_functions/cloud_functions.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gecies/gecies.dart';
import 'package:provider/provider.dart';
import '../../constants.dart';

class LoginScreen extends StatefulWidget {
  @override
  State createState() {
    return _LoginScreen();
  }
}

class _LoginScreen extends State<LoginScreen> {

  TextEditingController _emailController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
            color: isDarkMode(context) ? Colors.white : Colors.black),
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 24.0),
                child: Text('Sign In',
                  style: TextStyle(
                    color: Color(COLOR_PRIMARY),
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            FormInput(
              type: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              controller: _emailController,
              label: "Email",
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
            FormInput(
              type: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              controller: _passwordController,
              label: "Password",
              obscureText: true,
              onSubmitted: (password) => _login(_emailController.text, password),
            ),
            SizedBox(height: 32,),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                child: PrimaryButton(
                  label: "SIGN IN",
                  onTap: () {
                    _login(_emailController.text, _passwordController.text);
                  },
                )
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.all(32.0),
            //   child: Center(
            //     child: Text(
            //       'OR',
            //       style: TextStyle(
            //           color: isDarkMode(context) ? Colors.white : Colors.black),
            //     ),
            //   ),
            // ),
            // Padding(
            //   padding: const EdgeInsets.only(right: 40.0, left: 40.0, bottom: 20),
            //   child: FacebookLoginButton(),
            // ),
          ],
        ),
      ),
    );
  }

  Exception _validateInputs(String email, String password) {

    if (email.isEmpty) {
      showAlertDialog(context, 'E-mail address', 'E-mail address is required to login');
      return FormatException("email required");
    } else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      showAlertDialog(context, 'E-mail address', 'E-mail address is not valid');
      return FormatException("invalid email");
    } else if (password.isEmpty) {
      showAlertDialog(context, 'Password', 'Password is required to login');
      return FormatException("password required");
    }
      
    return null;
  }

  Future<String> _loginWithUserNameAndPassword(String email, String password) async {

    showProgress(context, 'Logging in...', false);
    
    try {

      UserCredential result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim()
      );

      KeyPair key = await getUserKeyPair(userID: result.user.uid);

      context.read<KeyPair>().publicKeyBase64 = key.publicKeyBase64;
      context.read<KeyPair>().privateKeyBase64 = key.privateKeyBase64;
      context.read<EncrypterState>().encrypter = (String message) async {
        return await Gecies.encrypt(key.publicKeyBase64, message);
      };

      return result.user.uid;

    } catch (exception) {
      
      Navigator.of(context).pop(); // Close Dialog

      if (exception is PlatformException) {
        switch (exception.code) {
          case 'ERROR_INVALID_EMAIL':
            showAlertDialog(context, 'Couldn\'t Authenticate', 'Email address is malformed.');
            break;
          case 'ERROR_WRONG_PASSWORD':
            showAlertDialog(context, 'Couldn\'t Authenticate', 'Wrong password.');
            break;
          case 'ERROR_USER_NOT_FOUND':
            showAlertDialog(context, 'Couldn\'t Authenticate',
                'No user corresponding to the given email address.');
            break;
          case 'ERROR_USER_DISABLED':
            showAlertDialog(
                context, 'Couldn\'t Authenticate', 'User has been disabled.');
            break;
          case 'ERROR_TOO_MANY_REQUESTS':
            showAlertDialog(context, 'Couldn\'t Authenticate',
                'Too many attempts to sign in as this user.');
            break;
          case 'ERROR_OPERATION_NOT_ALLOWED':
            showAlertDialog(context, 'Couldn\'t Authenticate',
                'Email & Password accounts are not enabled.');
            break;
        }
      } else if (exception is FirebaseFunctionsException) {
        showAlertDialog(context, 'We messed up :(', 'Something went wrong on our end.');
      } else if (exception is KeyException) {
        showAlertDialog(context, 'We messed up :(', 'Something unexpected happened.');
      }

      print(exception.toString());
      return Future.error("unable to sign in");

    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login(String email, String password) async {
    Exception validityException = _validateInputs(email, password);
    if (validityException == null) {
      await _loginWithUserNameAndPassword(email, password).then((String uid) {
        Navigator.of(context).pop();
        goToNextScreenAfterAuth(context, uid);
      }).catchError((Object e) {
        print(e.toString());
      });
    }
  }

}