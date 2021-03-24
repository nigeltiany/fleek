import 'dart:io';

import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/FormInput.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/StudentVerification/StudentVerification.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:dating/ui/signUp/functions.dart';
import 'package:dating/ui/terms/terms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

class SignUpScreen extends StatefulWidget {

  final SignUpInfo signUpInfo;

  const SignUpScreen({
    Key key,
    this.signUpInfo
  }) : super(key: key);

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
  bool obscurePassword = true;

  SharedPreferences prefs;

  @override
  void initState () {
    super.initState();
    prefs = context.read<SharedPreferences>();
  }

  Future<bool> hasAcceptedTermsAndConditions(BuildContext ctx) async {
    return (prefs.getBool(TERMS_ACCEPTED) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      if ((prefs.getBool(TERMS_ACCEPTED) ?? false) && !termsPopUpShown) {
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
      }
      return signUpScreen();
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

    if (widget.signUpInfo != null) {
      Future.delayed(Duration(seconds: 0), () {
        var validityResult =  hasValidityErrors(
            username: widget.signUpInfo.username,
            email: widget.signUpInfo.email,
            password: widget.signUpInfo.password
        );
        if (validityResult.hasAnError) {
          validityResult.usernameHasError ? usernameError = validityResult.usernameError : usernameError = null;
          validityResult.emailHasError ? emailError = validityResult.emailError : emailError = null;
          validityResult.passwordHasError ? passwordError = validityResult.passwordError : passwordError = null;
          setState(() {});
        }
      });
    }

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
          type: TextInputType.visiblePassword,
          textInputAction: TextInputAction.done,
          controller: _passwordController,
          label: "Password",
          obscureText: obscurePassword,
          suffixIcon: IconButton(
            iconSize: 18,
            padding: EdgeInsets.zero,
            splashRadius: 8,
            icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                obscurePassword = !obscurePassword;
              });
            },
          ),
          onSubmitted: (_) => validateThenNavigate,
        ),
        _showError(passwordError),
        SizedBox(height: 32,),
        ConstrainedBox(
          constraints: BoxConstraints(minWidth: double.infinity),
          child: Padding(
            padding: const EdgeInsets.only(right: 24.0, left: 24.0),
            child: PrimaryButton(
              label: "SIGN UP",
              onTap: validateThenNavigate
            ),
          ),
        ),
      ],
    );
  }

  validateThenNavigate () {
    var validityResult =  hasValidityErrors(
      username: _usernameController.text,
      email: _emailController.text,
      password: _passwordController.text
    );
    if (validityResult.hasAnError) {
      validityResult.usernameHasError ? usernameError = validityResult.usernameError : usernameError = null;
      validityResult.emailHasError ? emailError = validityResult.emailError : emailError = null;
      validityResult.passwordHasError ? passwordError = validityResult.passwordError : passwordError = null;
      setState(() {});
      return;
    }
    pushAndRemoveUntil(context,
      StudentVerificationScreen(
        signUpInfo: SignUpInfo(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text
        ),
      ),
      false,
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

  @override
  void dispose() {
    _passwordController.dispose();
    _usernameController.dispose();
    SharedPreferences.getInstance().then((prefs) => prefs.setBool(TERMS_ACCEPTED, false));
    super.dispose();
  }

}