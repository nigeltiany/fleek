import 'package:dating/components/PrimaryButton.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Gender.dart';
import 'package:dating/model/ProfileSettings.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: isDarkMode(context) ? Colors.black : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _title(),
              SizedBox(height: 24),
              _genderSelector(),
              SizedBox(height: 12),
              _orientationSelector(),
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
                color: Colors.black,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Gender", style: TextStyle(
              color: Colors.black,
              fontSize: 18
            ),
          ),
          SizedBox(height: 12,),
          TabBar(
            controller: _genderTabController,
            unselectedLabelColor: Color(COLOR_PRIMARY),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(COLOR_PRIMARY_DARK), Color(COLOR_PRIMARY)],
                ),
                borderRadius: BorderRadius.circular(50),
                color: Color(COLOR_PRIMARY_DARK)
            ),
            tabs: [
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Male"),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Female"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _orientationSelector () {
    return  Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Show me", style: TextStyle(
              color: Colors.black,
              fontSize: 18
            ),
          ),
          SizedBox(height: 12,),
          TabBar(
            controller: _orientationTabController,
            unselectedLabelColor: Color(COLOR_PRIMARY),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(COLOR_PRIMARY_DARK), Color(COLOR_PRIMARY)],
                ),
                borderRadius: BorderRadius.circular(50),
                color: Color(COLOR_PRIMARY_DARK)
            ),
            tabs: [
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Guys"),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Ladies"),
                ),
              ),
              Tab(
                child: Align(
                  alignment: Alignment.center,
                  child: Text("Everyone"),
                ),
              ),
            ],
          ),
        ],
      ),
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