import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/UserPrivateDetails.dart';
import 'package:dating/store/ChatData.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/MatchData.dart';
import 'package:dating/store/Store.dart';
import 'package:dating/ui/auth/AuthScreen.dart';
import 'package:dating/ui/onBoarding/OnBoardingScreen.dart';
import 'package:file/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:native_updater/native_updater.dart';
import 'package:new_version/new_version.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'constants.dart' as Constants;
import 'model/User.dart';

void main() async {
  InAppPurchaseConnection.enablePendingPurchases();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MyApp(
      store: Store(),
      secureStorage: FlutterSecureStorage(),
    )
  );
}

class MyApp extends StatefulWidget {

  final Store store;
  final FlutterSecureStorage secureStorage;

  const MyApp({
    Key key,
    @required this.store,
    @required this.secureStorage,
  }) : super(key: key);

  @override
  MyAppState createState() => MyAppState(store, secureStorage);

}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final Store store;
  final FlutterSecureStorage secureStorage;
  StreamSubscription tokenStream;
  NewVersion newVersion;

  MyAppState(this.store, this.secureStorage);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VersionStatus>(
      future: newVersion.getVersionStatus(),
      builder: (BuildContext context, AsyncSnapshot<VersionStatus> snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.canUpdate) {
            NativeUpdater.displayUpdateAlert(context,
              forceUpdate: true,
              iOSUpdateButtonLabel: 'Upgrade',
              iOSCloseButtonLabel: 'Exit',
            );
            return Container(color: Color(Constants.COLOR_PRIMARY_DARK));
          } else {
            return _app();
          }
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Color(Constants.COLOR_PRIMARY_DARK),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          return _app();
        }
      },
    );
  }

  Widget _app() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppUser>.value(value: store.appUser),
        ChangeNotifierProvider<FleekData>.value(value: store.fleekData),
        ChangeNotifierProvider<ChatData>.value(value: store.chatData),
        ChangeNotifierProvider<ConversationData>.value(value: store.conversationData),
        ChangeNotifierProvider<MatchData>.value(value: store.matchData),
        Provider<FlutterSecureStorage>.value(value: secureStorage),
        ChangeNotifierProvider<KeyPair>.value(value: KeyPair()),
        ChangeNotifierProvider<EncrypterState>.value(value: EncrypterState(null)),
        Provider<MemoryFileSystem>.value(value: MemoryFileSystem()),
      ],
      child: MaterialApp(
        title: 'Fleek',
        theme: ThemeData(
          colorScheme: ColorScheme.light(primary: Color(Constants.COLOR_PRIMARY)),
          accentColor: Color(Constants.COLOR_PRIMARY),
          primaryColor: Color(Constants.COLOR_PRIMARY),
          brightness: Brightness.light,
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: Colors.white.withOpacity(0.9)
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.dark(primary: Color(Constants.COLOR_PRIMARY)),
          accentColor: Color(Constants.COLOR_PRIMARY),
          primaryColor: Color(Constants.COLOR_PRIMARY),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: Colors.black12.withOpacity(0.3)
          ),
          brightness: Brightness.dark
        ),
        debugShowCheckedModeBanner: false,
        color: Color(Constants.COLOR_PRIMARY),
        home: OnBoarding()
      ),
    );
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();

    newVersion = NewVersion(context: context);

    FireStoreUtils.firebaseMessaging.configure(
      onBackgroundMessage: backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
      },
    );

    FireStoreUtils.firebaseMessaging.requestNotificationPermissions(
      const IosNotificationSettings(sound: true, badge: true, alert: true, provisional: true),
    );

    FireStoreUtils.firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });

    FirebaseAuth.instance.authStateChanges().where((User i) => i != null).listen((User u) async {

      AppUser databaseAppUserState = await FireStoreUtils.getCurrentUser();
      UserPrivateDetails userPrivateDetails = await FireStoreUtils.getCurrentUserPrivateDetails();

      if (databaseAppUserState == null) {
        store.appUser.userID = u.uid;
        store.appUser.signedIn = true;
      } else {
        store.appUser.signedIn = true;
        store.appUser.copy(databaseAppUserState);
        await FireStoreUtils.updateCurrentUser(store.appUser);
      }

      if (userPrivateDetails != null) {
        if (userPrivateDetails.fcmToken == null) {
          userPrivateDetails.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
          await FireStoreUtils.updateUserPrivateDetails(userPrivateDetails);
        } else {
          tokenStream = FireStoreUtils.firebaseMessaging.onTokenRefresh.listen((token) async {
            if (token != userPrivateDetails.fcmToken) {
              userPrivateDetails.fcmToken = token;
              await FireStoreUtils.updateUserPrivateDetails(userPrivateDetails);
            }
          });
        }
      }

    });

  }

  @override
  void dispose() {
    tokenStream.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (FirebaseAuth.instance.currentUser != null) {
      if (state == AppLifecycleState.paused) {
        tokenStream?.pause();
        store.appUser.online = false;
        store.appUser.lastOnlineTimestamp = Timestamp.now();
        FireStoreUtils.updateCurrentUser(store.appUser);
      } else if (state == AppLifecycleState.resumed) {
        tokenStream?.resume();
        store.appUser.online = true;
        store.appUser.lastOnlineTimestamp = Timestamp.now();
        FireStoreUtils.updateCurrentUser(store.appUser);
      }
    }
  }

}

class OnBoarding extends StatefulWidget {
  @override
  State createState() {
    return OnBoardingState();
  }
}

class OnBoardingState extends State<OnBoarding> {

  Future hasFinishedOnBoarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(Constants.FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      if (FirebaseAuth.instance.currentUser != null) {
        goToNextScreenAfterAuth(context);
      } else {
        pushReplacement(context, AuthScreen());
      }
    } else {
      pushReplacement(context, OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(Constants.COLOR_PRIMARY),
      body: FutureBuilder<void>(
        future: hasFinishedOnBoarding(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: isDarkMode(context) ? Colors.black : Colors.white,
              ),
            );
          }
          // Should never get to this point
          return Container(color: Color(Constants.COLOR_PRIMARY_DARK),);
        },
      ),
    );
  }

}


Future<dynamic> backgroundMessageHandler(Map<String, dynamic> message) {

  if (message.containsKey('data')) {
    // Handle data message
    print('backgroundMessageHandler message.containsKey(data)');
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
    print('backgroundMessageHandler message.containsKey(notification)');
  }
  // Or do other work.
}