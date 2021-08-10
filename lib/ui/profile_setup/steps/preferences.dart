import 'package:dating/components/GenderSelector.dart';
import 'package:dating/components/InterestSelector.dart';
import 'package:dating/components/OrientationSelector.dart';
import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Gender.dart';
import 'package:dating/model/ProfileSettings.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PreferencesSetup extends StatefulWidget {

  final PageController pageController;

  PreferencesSetup({
    Key key,
    @required this.pageController
  }) : super(key: key);

  @override
  _PreferencesSetupState createState() => _PreferencesSetupState(pageController);
}

class _PreferencesSetupState extends State<PreferencesSetup> with TickerProviderStateMixin {

  final PageController pageController;

  AppUser user;
  TabController _genderTabController;
  TabController _orientationTabController;
  TabController _searchInterestController;

  _PreferencesSetupState(this.pageController);

  @override
  void initState() {
    super.initState();
    user = context.read<AppUser>();
    if (user.settings == null) {
      user.settings = Settings();
    }

    user.settings.gender = Gender.FEMALE; // same as initialIndex 1 to start with
    _genderTabController = TabController(initialIndex: 1, length: 2, vsync: this);
    _genderTabController.addListener(() {
      user.settings.gender = _genderTabController.index == 0 ? Gender.MALE : Gender.FEMALE;
    });

    user.settings.genderPreference = GenderPreference.MALE; // same as initialIndex 0
    _orientationTabController = TabController(length: 3, vsync: this);
    _orientationTabController.addListener(() {
      user.settings.genderPreference = GenderPreference.values[_orientationTabController.index];
    });

    user.settings.searchInterest = SearchInterest.DATES;
    _searchInterestController = TabController(
      initialIndex: user.settings.searchInterest.index,
      length: SearchInterest.values.length,
      vsync: this,
    );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              _title(),
              SizedBox(height: 24),
              _genderSelector(),
              SizedBox(height: 12),
              _orientationSelector(),
              SizedBox(height: 12),
              _searchInterestSelector(),
              Spacer(),
              _nextScreenButton(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  dispose () {
    super.dispose();
    _genderTabController.dispose();
    _orientationTabController.dispose();
  }

  Widget _title () {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: double.infinity),
      child: Padding(
        padding: const EdgeInsets.only(top: 32.0, left: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences',
              style: TextStyle(
                color: Color(COLOR_PRIMARY_DARK),
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 12),
            Text('let\'s get your preferences setup',
              style: TextStyle(
                color: isDarkMode(context) ? Colors.white : Colors.black,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _genderSelector () {
    return  Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GenderSelector(tabController: _genderTabController),
    );
  }

  Widget _orientationSelector () {
    return  Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: OrientationSelector(tabController: _orientationTabController),
    );
  }

  Widget _searchInterestSelector () {
    return  Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: InterestSelector(tabController: _searchInterestController),
    );
  }

  Widget _nextScreenButton () {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 48),
      child: SizedBox(
        width: double.infinity,
        child: PrimaryButton(
          label: "Continue",
          onTap: () async {
            await pageController.nextPage(duration: Duration(milliseconds: 400), curve: Curves.easeIn);
          },
        ),
      ),
    );
  }


}