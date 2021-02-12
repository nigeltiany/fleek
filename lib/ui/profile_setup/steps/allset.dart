import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/home/HomeScreen.dart';
import 'package:flutter/material.dart';

class AllSet extends StatelessWidget {

  final PageController pageController;

  const AllSet({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Spacer(),
              _motive(),
              Spacer(),
              _nextScreenButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _motive () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('All Set!',
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12),
            // Text('Go get them and remember to be respectful. ',
            //   style: TextStyle(
            //     color: Colors.black,
            //     fontSize: 16,
            //     decoration: TextDecoration.none,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _nextScreenButton (BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Continue",
          onTap: () async {
            UserPrivateDetails userPrivateDetails = await FireStoreUtils.getCurrentUserPrivateDetails();
            userPrivateDetails.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
            await FireStoreUtils.updateUserPrivateDetails(userPrivateDetails);
            pushAndRemoveUntil(context, HomeScreen(), false);
          },
        ),
      ),
    );
  }

}
