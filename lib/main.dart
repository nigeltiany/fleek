import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/store/KeyPair.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:dating/services/helper.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';

import 'constants.dart' as Constants;
import 'model/User.dart';

void main() async {
  InAppPurchaseConnection.enablePendingPurchases();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  AppUser user = AppUser();
  runApp(
    MyApp(
      user: user,
      secureStorage: FlutterSecureStorage(),
    )
  );
}

class MyApp extends StatefulWidget {

  final AppUser user;
  final FlutterSecureStorage secureStorage;

  const MyApp({
    Key key,
    @required this.user,
    @required this.secureStorage,
  }) : super(key: key);

  @override
  MyAppState createState() => MyAppState(user, secureStorage);

}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final AppUser user;
  final FlutterSecureStorage secureStorage;
  StreamSubscription tokenStream;

  MyAppState(this.user, this.secureStorage);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppUser>.value(value: user),
        ChangeNotifierProvider<FleekData>.value(value: FleekData()),
        Provider<FlutterSecureStorage>.value(value: secureStorage),
        Provider<KeyPair>.value(value: KeyPair()),
        Provider<EncrypterState>.value(value: EncrypterState(null)),
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
            backgroundColor: Colors.white.withOpacity(.9)
          ),
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.dark(primary: Color(Constants.COLOR_PRIMARY)),
          accentColor: Color(Constants.COLOR_PRIMARY),
          primaryColor: Color(Constants.COLOR_PRIMARY),
          bottomSheetTheme: BottomSheetThemeData(
            backgroundColor: Colors.black12.withOpacity(.3)
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

    FirebaseAuth.instance.authStateChanges().firstWhere((User i) => i != null).then((User u) async {
      AppUser dbUser = await FireStoreUtils().getCurrentUser(u.uid);
      if (dbUser == null) {
        user.userID = u.uid;
        user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken();
        user.settings.showMe = false;
        FireStoreUtils.updateCurrentUser(user);
        return;
      }
      user.copy(dbUser);
      tokenStream = FireStoreUtils.firebaseMessaging.onTokenRefresh.listen((token) {
        if (token != user.fcmToken) {
          user.fcmToken = token;
          FireStoreUtils.updateCurrentUser(user);
        }
      });
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
    if (FirebaseAuth.instance.currentUser != null && user != null) {
      if (state == AppLifecycleState.paused) {
        //user offline
        tokenStream?.pause();
        user.active = false;
        user.lastOnlineTimestamp = Timestamp.now();
        FireStoreUtils.updateCurrentUser(user);
      } else if (state == AppLifecycleState.resumed) {
        //user online
        tokenStream?.resume();
        user.active = true;
        FireStoreUtils.updateCurrentUser(user);
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
      User firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        goToNextScreenAfterAuth(context, firebaseUser.uid);
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
    hasFinishedOnBoarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(Constants.COLOR_PRIMARY),
      body: Center(
        child: CircularProgressIndicator(
          backgroundColor: isDarkMode(context) ? Colors.black : Colors.white,
        ),
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