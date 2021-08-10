import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/components/ProfileImagePicker.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class ProfileImageSetter extends StatelessWidget {

  final PageController pageController;

  const ProfileImageSetter({
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
              _title(),
              Spacer(),
              ProfileImagePicker(),
              Spacer(),
              _nextScreenButton(context),
            ],
          )
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
            Text('Profile Picture',
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12),
            Text('Add your profile picture',
              style: TextStyle(
                color: Color(COLOR_PRIMARY),
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nextScreenButton (BuildContext context) {
    return Consumer<AppUser>(
      builder: (context, user, _) {
        return Padding(
          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
          child: SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: "Continue",
              onTap: user.profilePictureURL == null || user.profilePictureURL.isEmpty ? null : _nextPage,
            ),
          ),
        );
      }
    );
  }

  _nextPage () async {
    await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
  }

}