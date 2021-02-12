import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/ui/profile_setup/steps/allset.dart';
import 'package:provider/provider.dart';
import 'package:dating/model/ProfileSetup.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/ui/profile_setup/steps/bio.dart';
import 'package:dating/ui/profile_setup/steps/congratulations.dart';
import 'package:dating/ui/profile_setup/steps/preferences.dart';
import 'package:dating/ui/profile_setup/steps/location.dart';
import 'package:dating/ui/profile_setup/steps/profile_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {

  final String phoneNumber;
  final ProfileSetupStep step;

  const ProfileSetupScreen({
    Key key,
    this.phoneNumber,
    this.step,
  }) : super(key: key);

  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState(
    phoneNumber: phoneNumber,
    jumpToStep: step ?? ProfileSetupStep.NOT_STARTED
  );
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {

  AppUser user;
  PageController pageController;
  ProfileSetupStep jumpToStep;

  final String phoneNumber;
  final String userID;

  final Map<int, ProfileSetupStep> order = {
    0 : ProfileSetupStep.NOT_STARTED,
    1 : ProfileSetupStep.PROFILE_PICTURE,
    2 : ProfileSetupStep.PREFERENCES,
    3 : ProfileSetupStep.BIO,
    4 : ProfileSetupStep.LOCATION,
    5 : ProfileSetupStep.COMPLETE,
  };

  _ProfileSetupScreenState({
    this.userID,
    this.phoneNumber,
    this.jumpToStep
  });

  @override
  void initState() {
    super.initState();

    pageController = PageController(initialPage: order.values.toList().indexOf(jumpToStep));
    pageController.addListener(() async {
      await FireStoreUtils.updateCurrentUser(context.read<AppUser>());
    });

    user = context.read<AppUser>();
  }

  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return PageView(
      physics: NeverScrollableScrollPhysics(),
      controller: pageController,
      onPageChanged: (int page) async {
        await FireStoreUtils.firestore
          .collection(USER_PROFILE_SETUP)
          .doc(FirebaseAuth.instance.currentUser.uid)
          .set(ProfileSetupStatus(step: order[page]).toJson(), SetOptions(merge : true));
      },
      children: [
        Congrats(pageController: pageController),
        ProfileImageSetter(pageController: pageController),
        PreferencesSetup(pageController: pageController),
        BioSetup(pageController: pageController),
        AllowLocationServices(pageController: pageController),
        AllSet(pageController: pageController),
      ],
    );

  }
}
