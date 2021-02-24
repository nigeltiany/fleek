import 'package:dating/components/GenderSelector.dart';
import 'package:dating/components/InterestSelector.dart';
import 'package:dating/components/OrientationSelector.dart';
import 'package:dating/model/Gender.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/ui/SwipeScreen/SwipeScreen.dart';
import 'package:dating/ui/accountDetails/AccountDetailsScreen.dart';
import 'package:dating/ui/conversationsScreen/ConversationsScreen.dart';
import 'package:dating/ui/matchScreen/MatchScreen.dart';
import 'package:dating/ui/profile/ProfileScreen.dart';
import 'package:dating/ui/settings/SettingsScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';

enum DrawerSelection { Conversations, Contacts, Search, Profile }

class HomeScreen extends StatefulWidget {
  static bool onGoingCall = false;

  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeState createState() {
    return _HomeState();
  }
}

class _HomeState extends State<HomeScreen> with TickerProviderStateMixin {

  AppUser user;

  int _currentIndex = 1;

  TabController _genderTabController;
  TabController _orientationTabController;
  TabController _searchInterestController;
  bool showingNewMatchPopUp; // leave as null

  @override
  void initState() {
    super.initState();
    user = context.read<AppUser>();

    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<FleekData>().loadData(user);
      context.read<MatchData>().matchStream.listen((FleekMatch match) async {
        await Future.delayed(Duration(seconds: showingNewMatchPopUp == null ? 3 : 0), () => Future.value(null));
        if (showingNewMatchPopUp == null) {
          showingNewMatchPopUp = false;
        }
        if (!match.seen && !showingNewMatchPopUp) {
          showingNewMatchPopUp = true;
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return MatchScreen();
            },
          );
          showingNewMatchPopUp = false;
          var unseenMatches = Provider.of<MatchData>(context, listen: false).matches.where((m) => !m.seen).toList();
          await Future.forEach(unseenMatches, (FleekMatch m) async {
            await Provider.of<MatchData>(context, listen: false).setMatchAsSeen(m);
          });
        }
      });
    });

    _genderTabController = TabController(
      initialIndex: user.settings.gender.index,
      length: Gender.values.length,
      vsync: this,
    );

    _orientationTabController = TabController(
      initialIndex: user.settings.genderPreference.index,
      length: GenderPreference.values.length,
      vsync: this,
    );

    _searchInterestController = TabController(
      initialIndex: user.settings.searchInterest.index,
      length: SearchInterest.values.length,
      vsync: this,
    );

    [_genderTabController, _orientationTabController, _searchInterestController].forEach((controller) {
      controller.addListener(() async {
        user.settings.gender = _genderTabController.index == 0 ? Gender.MALE : Gender.FEMALE;
        user.settings.genderPreference = GenderPreference.values[_orientationTabController.index];
        user.settings.searchInterest = SearchInterest.values[_searchInterestController.index];
        await FireStoreUtils.updateCurrentUser(context.read<AppUser>());
      });
    });

  }

  @override
  void dispose() {
    [_genderTabController, _orientationTabController, _searchInterestController].forEach((controller) {
      controller.dispose();
    });
    context.read<FleekData>().clean();
    super.dispose();
  }

  Widget _logo({ bool active = false }) {
    return Image.asset('assets/images/app_logo.png',
      width: active ? 40 : 24,
      height: active ? 40 : 24,
      color: active ? Color(COLOR_PRIMARY) : Colors.grey,
    );
  }

  Widget _leadingWidgetIcon() {
    switch (_currentIndex) {
      case 0:
        return IconButton(
          icon: Icon(Icons.settings, color: Colors.grey),
          onPressed: () {
            push(context, SettingsScreen());
          },
        );
      case 1:
        // TODO: Return heart icon with unseen matches count
        return Container();
      default:
        return Container();
    }
  }

  Iterable<Widget> _trailingWidgetIcon () {
    Widget button;
    if (_currentIndex == 0) {
      button = IconButton(
        icon: Icon(Icons.account_circle_rounded, color: Colors.grey),
        onPressed: () {
          push(context, AccountDetailsScreen(user: user));
        },
      );
    } else if (_currentIndex == 1) {
      button = IconButton(
        icon: Icon(Icons.tune, color: Colors.grey),
        onPressed: showFiltersBottomSheet,
      );
    } else {
      button = Container();
    }
    return [button];
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: user,
      child: Consumer<AppUser>(
        builder: (context, user, _) {
          return Scaffold(
            appBar: AppBar(
              centerTitle: true,
              title: Text("Fleek",
                style: TextStyle(
                  fontSize: 24,
                  color: Color(COLOR_PRIMARY),
                ),
              ),
              leading: _leadingWidgetIcon(),
              actions: _trailingWidgetIcon(),
              backgroundColor: Colors.transparent,
              brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
              elevation: 0,
            ),
            body: IndexedStack(
              index: _currentIndex,
              children: [
                ProfileScreen(),
                SwipeScreen(),
                ConversationsScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              elevation: 0,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              currentIndex: _currentIndex,
              backgroundColor: Colors.transparent,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: [
                BottomNavigationBarItem(
                  label: "",
                  icon: Icon(Icons.person),
                  activeIcon: Icon(Icons.person, size: 40),
                ),
                BottomNavigationBarItem(
                  label: "",
                  icon: _logo(),
                  activeIcon: _logo(active: true),
                ),
                BottomNavigationBarItem(
                  label: "",
                  icon: Icon(Icons.forum),
                  activeIcon: Icon(Icons.forum, size: 40),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  showFiltersBottomSheet() async {
    await showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          color: isDarkMode(context) ? Color(DARK_MODE_SCAFFOLD) : Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GenderSelector(tabController: _genderTabController),
                SizedBox(height: 24),
                OrientationSelector(tabController: _orientationTabController),
                SizedBox(height: 24),
                InterestSelector(tabController: _searchInterestController)
              ],
            ),
          ),
        );
      },
    );
    context.read<FleekData>().removeAllUsers();
    context.read<FleekData>().loadData(user);
  }

}
