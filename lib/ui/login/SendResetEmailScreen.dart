import 'package:dating/components/FormInput.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class SendResetEmailScreen extends StatefulWidget {
  @override
  State createState() {
    return _SendResetEmailScreen();
  }
}

class _SendResetEmailScreen extends State<SendResetEmailScreen> {

  TextEditingController _emailController = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
        elevation: 0.0,
        centerTitle: true,
        title: Image.asset('assets/images/app_logo.png',
          width: 42.0,
          height: 42.0,
          fit: BoxFit.cover,
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(top: 32.0, left: 24.0),
                child: Text('Password Reset',
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
              textInputAction: TextInputAction.done,
              controller: _emailController,
              label: "Email",
              onSubmitted: (_) => _sendPasswordResetEmail(_emailController.text),
            ),
            SizedBox(height: 32,),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                child: PrimaryButton(
                  label: "Send Reset Email",
                  onTap: () {
                    _sendPasswordResetEmail(_emailController.text);
                  },
                ),
              ),
            ),
            SizedBox(height: 32,),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, left: 24.0),
                child: SecondaryButton(
                  label: "Sign in",
                  onTap: () {
                    pushAndRemoveUntil(context, AuthScreen(), false);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Exception _validateInputs(String email) {

    if (email.isEmpty) {
      showAlertDialog(context, 'E-mail address', 'E-mail address is required to login');
      return FormatException("email required");
    } else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email)) {
      showAlertDialog(context, 'E-mail address', 'E-mail address is not valid');
      return FormatException("invalid email");
    } else if (email.endsWith(".edu") || email.endsWith(".org")) {
      showAlertDialog(context, 'E-mail address hint', 'Fleek only accepts personal emails. Are you sure you used this email to sign up?');
      return FormatException("invalid email");
    }

    return null;

  }

  void _sendPasswordResetEmail(String email) async {
    Exception validityException = _validateInputs(email);
    if (validityException == null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email)
        .then((value) {
          showSuccessDialog(context, "If $email is associated with a fleek account, you should receive an email with instructions on resetting your password.");
        })
        .catchError((e) {
          showAlertDialog(context, "Password reset failed", (e as FirebaseAuthException).message);
        });
    }
  }

  void showSuccessDialog(BuildContext context, String content) {
    // set up the AlertDialog
    Widget okButton = FlatButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.of(context).pop();
        pushAndRemoveUntil(context, AuthScreen(), false);
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Email Sent",
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

}