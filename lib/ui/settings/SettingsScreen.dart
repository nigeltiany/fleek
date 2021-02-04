import 'package:dating/model/Gender.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

class SettingsScreen extends StatefulWidget {

  const SettingsScreen({Key key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  AppUser user;

  _SettingsScreenState();

  bool showMe, newMatches, messages, superLikes, topPicks;

  num radius;
  Gender gender;
  GenderPreference prefGender;

  @override
  void initState() {
    user = context.read<AppUser>();
    showMe = user.settings.showMe;
    newMatches = user.settings.pushNewMatchesEnabled;
    messages = user.settings.pushNewMessages;
    superLikes = user.settings.pushSuperLikesEnabled;
    topPicks = user.settings.pushTopPicksEnabled;
    radius = user.settings.distanceRadius;
    gender = user.settings.gender;
    prefGender = user.settings.genderPreference;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        iconTheme: IconThemeData(color: isDarkMode(context) ? Colors.white : Colors.black),
        backgroundColor: isDarkMode(context) ? Colors.black : Colors.transparent,
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        centerTitle: true,
        title: Text('Settings',
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: SettingsList(
          backgroundColor: Colors.transparent,
          sections: [
            SettingsSection(
              title: 'Discovery',
              tiles: [
                SettingsTile.switchTile(
                  title: 'Show me on Fleek',
                  // leading: Icon(Icons.fingerprint),
                  switchValue: true,
                  onToggle: (bool value) {},
                ),
                SettingsTile(
                  title: 'Distance Radius',
                  subtitle: '3 KM',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
              ],
            ),
            SettingsSection(
              title: 'Notifications',
              tiles: [
                SettingsTile.switchTile(
                  title: 'New matches',
                  // leading: Icon(Icons.fingerprint),
                  switchValue: true,
                  onToggle: (bool value) {},
                ),
                SettingsTile.switchTile(
                  title: 'Super Likes',
                  // leading: Icon(Icons.fingerprint),
                  switchValue: true,
                  onToggle: (bool value) {},
                ),
                SettingsTile.switchTile(
                  title: 'New Messages',
                  // leading: Icon(Icons.fingerprint),
                  switchValue: true,
                  onToggle: (bool value) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
