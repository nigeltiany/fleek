import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/User.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/ChatData.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/store/LikeData.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/store/Store.dart';
import 'package:dating/ui/StudentVerification/StudentVerification.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AppUser user;

  AccountDetailsScreen({Key key, @required this.user}) : super(key: key);

  @override
  _AccountDetailsScreenState createState() {
    return _AccountDetailsScreenState(user);
  }
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {

  AppUser user;
  int age;
  String firstName, lastName, bio, school, email, mobile;

  _AccountDetailsScreenState(this.user);

  @override
  void initState() {
    super.initState();
    user = context.read<AppUser>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        brightness: isDarkMode(context) ? Brightness.dark : Brightness.light,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDarkMode(context) ? Colors.white : Colors.black,
        ),
        title: Text('Account Details',
          style: TextStyle(
            color: isDarkMode(context) ? Colors.white : Colors.black,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: FutureBuilder<UserPrivateDetails>(
          future: FireStoreUtils.getCurrentUserPrivateDetails(),
          builder: (BuildContext context, AsyncSnapshot<UserPrivateDetails> snapshot) {
            if (snapshot.hasData || snapshot.connectionState == ConnectionState.done) {
              return _sections(snapshot.data ?? UserPrivateDetails());
            } else if (snapshot.hasError) {
              return Center(child: Icon(Icons.error, color: Colors.redAccent,));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Widget _sections (UserPrivateDetails details) {
    return SettingsList(
      backgroundColor: Colors.transparent,
      sections: [
        SettingsSection(
          title: 'Discovery',
          tiles: [
            SettingsTile.switchTile(
              title: 'Show me on Fleek',
              // leading: Icon(Icons.fingerprint),
              switchActiveColor: Color(COLOR_PRIMARY),
              switchValue: user.settings.showMe,
              onToggle: (bool value) async {
                user.settings.showMe = value;
                await FireStoreUtils.updateCurrentUser(user);
                setState(() {});
              },
            ),
            // SettingsTile(
            //   title: 'Distance Radius',
            //   subtitle: '3 KM',
            //   // leading: Icon(Icons.language),
            //   onPressed: (BuildContext context) {},
            // ),
          ],
        ),
        SettingsSection(
          title: 'Notifications',
          tiles: [
            SettingsTile.switchTile(
              title: 'New matches',
              // leading: Icon(Icons.fingerprint),
              switchActiveColor: Color(COLOR_PRIMARY),
              switchValue: user.settings.pushNewMatchesEnabled,
              onToggle: (bool value) async {
                user.settings.pushNewMatchesEnabled = value;
                await FireStoreUtils.updateCurrentUser(user);
                setState(() {});
              },
            ),
            SettingsTile.switchTile(
              title: 'New Messages',
              // leading: Icon(Icons.fingerprint),
              switchActiveColor: Color(COLOR_PRIMARY),
              switchValue: user.settings.pushNewMessages,
              onToggle: (bool value) async {
                user.settings.pushNewMessages = value;
                await FireStoreUtils.updateCurrentUser(user);
                setState(() {});
              },
            ),
          ],
        ),
        SettingsSection(
          title: 'Public Info',
          tiles: [
            SettingsTile(
              title: 'Username',
              subtitle: user.userName,
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) {},
            ),
            SettingsTile(
              title: 'Age',
              subtitle: user.birthDate != null ? '${getUserAge(user.birthDate)}' : '',
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) async {
                var now = DateTime.now();
                var eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
                var dob = await showDatePicker(
                  context: context,
                  initialDate: user.birthDate == null ? eighteenYearsAgo : user.birthDate.toDate(),
                  firstDate: now.subtract(Duration(days: 365 * 35)),
                  lastDate: eighteenYearsAgo,
                );
                if (dob != null) {
                  user.birthDate = Timestamp.fromDate(dob);
                  setState(() {});
                  FireStoreUtils.updateCurrentUser(user);
                }
              },
            ),
            SettingsTile(
              title: 'School',
              subtitle: "${user.school ?? 'Not set'}",
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) {},
            ),
          ],
        ),
        SettingsSection(
          title: 'Private Details',
          tiles: [
            SettingsTile(
              title: 'First Name',
              subtitle: details.firstName,
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) {},
            ),
            SettingsTile(
              title: 'Last Name',
              subtitle: details.lastName,
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) {},
            ),
            SettingsTile(
              title: 'Email Address',
              subtitle: details.email,
              // leading: Icon(Icons.language),
              onPressed: (BuildContext context) {},
            ),
            // SettingsTile(
            //   title: 'Phone Number',
            //   subtitle: '9192223333',
            //   // leading: Icon(Icons.language),
            //   onPressed: (BuildContext context) {},
            // ),
          ],
        ),
        SettingsSection(
          title: 'Account',
          tiles: [
            SettingsTile(
              title: "Logout",
              onPressed: (_) async {

                List<DataStore> _store = [
                  Provider.of<ChatData>(context, listen: false),
                  Provider.of<ConversationData>(context, listen: false),
                  Provider.of<FleekData>(context, listen: false),
                  Provider.of<MatchData>(context, listen: false),
                  Provider.of<LikeData>(context, listen: false),
                ]..forEach((store) {
                  store.closeFirebaseStreams();
                  store.clearData();
                });

                Provider.of<SharedPreferences>(context, listen: false).remove(VERIFICATION_ID_KEY);

                user.signedIn = false;
                user.settings.showMe = false;
                user.lastOnlineTimestamp = Timestamp.now();
                await FireStoreUtils.updateCurrentUser(user);
                await FirebaseAuth.instance.signOut();
                user.reset();

                Provider.of<Store>(context, listen: false).rebuild();

                pushAndRemoveUntil(context, AuthScreen(), false);
              },
            ),
          ],
        ),
      ],
    );
  }

}
