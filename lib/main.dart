import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/components/ButtonType.dart';
import 'package:dating/components/SecondaryButton.dart';
import 'package:dating/model/Notification.dart';
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
import 'package:dating/ui/chat/ChatScreen.dart';
import 'package:dating/ui/onBoarding/OnBoardingScreen.dart';
import 'package:file/memory.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:launch_review/launch_review.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:native_updater/native_updater.dart';
import 'package:new_version/new_version.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:version/version.dart';

import 'constants.dart' as Constants;
import 'model/User.dart';

void main() async {
  // InAppPurchaseConnection.enablePendingPurchases();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Disable persistence to get the latest data from firestore
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: false, // !important
    sslEnabled: true,
  );

  var sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    MyApp(
      store: Store(),
      secureStorage: FlutterSecureStorage(),
      sharedPreferences: sharedPreferences,
    )
  );
}

var _lightTheme = ThemeData(
  colorScheme: ColorScheme.light(primary: Color(Constants.COLOR_PRIMARY)),
  accentColor: Color(Constants.COLOR_PRIMARY),
  primaryColor: Color(Constants.COLOR_PRIMARY),
  brightness: Brightness.light,
  bottomSheetTheme: BottomSheetThemeData(
    backgroundColor: Colors.white.withOpacity(0.9)
  ),
);

var _darkTheme = ThemeData(
    colorScheme: ColorScheme.dark(primary: Color(Constants.COLOR_PRIMARY)),
    accentColor: Color(Constants.COLOR_PRIMARY),
    primaryColor: Color(Constants.COLOR_PRIMARY),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: Colors.black12.withOpacity(0.3)
    ),
    brightness: Brightness.dark
);

class MyApp extends StatefulWidget {

  final Store store;
  final FlutterSecureStorage secureStorage;
  final SharedPreferences sharedPreferences;

  const MyApp({
    Key key,
    @required this.store,
    @required this.secureStorage,
    @required this.sharedPreferences,
  }) : super(key: key);

  @override
  MyAppState createState() => MyAppState(store, secureStorage);

}

class MyAppState extends State<MyApp> with WidgetsBindingObserver {

  final Store store;
  final FlutterSecureStorage secureStorage;
  StreamSubscription tokenStream;
  NewVersion newVersion;
  bool userFetched = false;
  final _navigatorKey = GlobalKey<NavigatorState>();

  MyAppState(this.store, this.secureStorage);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<VersionStatus>(
      future: newVersion.getVersionStatus(),
      builder: (BuildContext context, AsyncSnapshot<VersionStatus> snapshot) {
        if (snapshot.hasData) {
          // canUpdate only checks for string equality
          if (snapshot.data.canUpdate) {
            var localVersion = Version.parse(snapshot.data.localVersion);
            var storeVersion = Version.parse(snapshot.data.storeVersion);
            if ((localVersion > storeVersion) || (localVersion.major == storeVersion.major && localVersion.minor == storeVersion.minor)) {
              return _app();
            }
            return _updateRequired();
          }
          return _app();
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Color(Constants.COLOR_PRIMARY_DARK),
            child: Center(
              child: CircularProgressIndicator(
                backgroundColor: Color(Constants.COLOR_PRIMARY_DARK),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            ),
          );
        } else {
          return _app();
        }
      },
    );
  }

  MaterialApp _updateRequired () {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.system_update, color: Color(Constants.COLOR_PRIMARY_DARK), size: 128,),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              child: Text("There is a new version of fleek available. \nKindly update to the latest version.",
                style: TextStyle(
                  decoration: TextDecoration.none,
                  fontSize: 18,
                  color: Color(Constants.COLOR_PRIMARY_DARK)
                ),
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: double.infinity),
              child: Padding(
                padding: const EdgeInsets.only(right: 32.0, left: 32.0),
                child: SecondaryButton(
                  label: "Update",
                  onTap: () {
                    LaunchReview.launch();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
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
        ChangeNotifierProvider<KeyPair>.value(value: KeyPair()),
        ChangeNotifierProvider<EncrypterState>.value(value: EncrypterState(null)),
        Provider<FlutterSecureStorage>.value(value: secureStorage),
        Provider<MemoryFileSystem>.value(value: MemoryFileSystem()),
        Provider<SharedPreferences>.value(value: widget.sharedPreferences),
      ],
      child: MaterialApp(
        title: 'Fleek',
        navigatorKey: _navigatorKey,
        theme: _lightTheme,
        darkTheme: _darkTheme,
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
      // onBackgroundMessage: backgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        // TODO: add counter bubble if message is a text message
        print("onMessage: $message");
      },
      onLaunch: (Map<String, dynamic> message) async {
        handleNotificationAction(message);
      },
      onResume: (Map<String, dynamic> message) async {
        handleNotificationAction(message);
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
        userFetched = true;
        store.appUser.userID = u.uid;
        store.appUser.signedIn = true;
      } else {
        userFetched = true;
        store.appUser.signedIn = true;
        store.appUser.copy(databaseAppUserState);
        await FireStoreUtils.updateCurrentUser(store.appUser);
      }

      if (userPrivateDetails != null) {
        var currentToken = await FireStoreUtils.firebaseMessaging.getToken();
        if (userPrivateDetails.fcmToken != currentToken) {
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
    if (FirebaseAuth.instance.currentUser != null && userFetched) {
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

  void handleNotificationAction(Map<String, dynamic> message) {

    if (FirebaseAuth.instance.currentUser == null) return;
    var notification = FleekNotification.fromMap(message);

    switch(notification.notificationType) {
      case NotificationType.MATCH:
        // TODO: Handle this case.
        break;
      case NotificationType.MESSAGE:
        push(_navigatorKey.currentContext, ChatScreen(identifiableUser: UserID(notification.senderUserID)));
        break;
      case NotificationType.UNKNOWN:
        break;
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

  Future hasFinishedOnBoarding(BuildContext ctx) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool finishedOnBoarding = (prefs.getBool(Constants.FINISHED_ON_BOARDING) ?? false);

    if (finishedOnBoarding) {
      if (FirebaseAuth.instance.currentUser != null) {
        goToNextScreenAfterAuth(ctx);
      } else {
        pushReplacement(ctx, AuthScreen());
      }
    } else {
      pushReplacement(ctx, OnBoardingScreen());
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(Constants.COLOR_PRIMARY_DARK),
      body: FutureBuilder<void>(
        future: hasFinishedOnBoarding(context),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Color(Constants.COLOR_PRIMARY_DARK),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
              ),
            );
          }
          // Should never get to this point
          return Container(color: Color(Constants.COLOR_PRIMARY_DARK));
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