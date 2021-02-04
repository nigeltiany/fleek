import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:settings_ui/settings_ui.dart';

import '../../constants.dart';

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
  GlobalKey<FormState> _key = new GlobalKey();
  AutovalidateMode _validate = AutovalidateMode.disabled;
  int age;
  String firstName, lastName, bio, school, email, mobile;

  _AccountDetailsScreenState(this.user);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDarkMode(context) ? Colors.black : Colors.transparent,
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
        child: SettingsList(
          backgroundColor: Colors.transparent,
          sections: [
            SettingsSection(
              title: 'Public Info',
              tiles: [
                SettingsTile(
                  title: 'Username',
                  subtitle: 'some-username',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
                SettingsTile(
                  title: 'Age',
                  subtitle: '18',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
                SettingsTile(
                  title: 'School',
                  subtitle: 'NCAT',
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
                  subtitle: 'Male',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
                SettingsTile(
                  title: 'Last Name',
                  subtitle: 'Three',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
                SettingsTile(
                  title: 'Email Address',
                  subtitle: 'some_private_non_school_email@mail.com',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
                SettingsTile(
                  title: 'Phone Number',
                  subtitle: '9192223333',
                  // leading: Icon(Icons.language),
                  onPressed: (BuildContext context) {},
                ),
              ],
            ),
            SettingsSection(
              title: 'Account',
              tiles: [
                SettingsTile(
                  title: "Logout",
                  onPressed: (_) async {
                    user.active = false;
                    user.lastOnlineTimestamp = Timestamp.now();
                    await FireStoreUtils.updateCurrentUser(user);
                    await FirebaseAuth.instance.signOut();
                    await context.read<FlutterSecureStorage>().deleteAll();
                    context.read<AppUser>().copy(AppUser());
                    pushAndRemoveUntil(context, AuthScreen(), false);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
