import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/StudentStatus.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/StudentVerification/StudentVerification.dart';
import 'package:flutter/material.dart';

class EmailSent extends StatelessWidget {

  final StudentStatus status;
  final Function resendEmail;
  final String studentEmail;

  const EmailSent({
    Key key,
    @required this.status,
    @required this.resendEmail,
    @required this.studentEmail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _title(),
            _instructions(),
            _nextScreenButton()
          ],
        ),
      ),
    );
  }

  Widget _title () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email Sent',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _instructions () {
    var style = TextStyle(
      fontSize: 18,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 56),
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("We sent you an email at: ", style: style),
            Text("$studentEmail",
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: style.fontSize,
              ),
            ),
            SizedBox(height: 16),
            Text("Follow the instructions in the email to get your account approved.", style: style),
            SizedBox(height: 16),
            Text("The app will refresh automatically after approval.", style: style),
          ],
        )
      ),
    );
  }

  Widget _nextScreenButton () {
    var secondsAgo = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(status.emailedAt.millisecondsSinceEpoch)).inSeconds;

    return FutureBuilder<int>(
      future: secondsAgo < 60 ? Future<int>.delayed(Duration(seconds: 60 - secondsAgo), () => 0) : Future<int>.value(0),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: "Edit Email",
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: PrimaryButton(
                    label: "Resend Email",
                    onTap: () {
                      Navigator.of(context).pop();
                      this.resendEmail();
                    },
                  ),
                )
              ],
            ),
          );
        } else {
          return Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
            child: SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: "Resend Email",
              ),
            ),
          );
        }
      }
    );
  }

}