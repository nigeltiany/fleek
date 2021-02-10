import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';

import '../../constants.dart' as Constants;
import '../../constants.dart';
import '../login/LoginScreen.dart';
import '../signUp/SignUpScreen.dart';

class AuthScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 70.0, bottom: 16.0),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: 150.0,
                  height: 150.0,
                  color: Color(Constants.COLOR_PRIMARY),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 0, right: 32, bottom: 8),
              child: Text(
                'Fleek',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(Constants.COLOR_PRIMARY),
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Match and chat with Aggies',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: PrimaryButton(
                  label: "Sign in",
                  onTap: () {
                    push(context, LoginScreen());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 40.0, left: 40.0, top: 20, bottom: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: double.infinity),
                child: SecondaryButton(
                  label: "Create Account",
                  onTap: () {
                    push(context, SignUpScreen());
                  },
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
