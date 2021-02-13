import 'dart:async';

import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:flutter/foundation.dart';

class FleekData with ChangeNotifier {

  static int MAX_FETCH_COUNT = 10;

  StreamController<AppUser> _streamController;

  Stream<AppUser> _stream;
  Stream<AppUser> get stream => _stream;

  int _recentlyFetchedCount;

  int get recentlyFetchedCount => _recentlyFetchedCount;

  void clean() {
    _streamController.close();
  }
  
  FleekData () {
    _streamController = StreamController<AppUser>();
    _stream = _streamController.stream.asBroadcastStream();
  }
  
  List<AppUser> _users = List<AppUser>();

  List<AppUser> get users => List.unmodifiable(_users);
  
  AppUser _previousLeftSwipedUser;

  AppUser get previousLeftSwipedUser => _previousLeftSwipedUser;

  set previousLeftSwipedUser(AppUser u) {
    _previousLeftSwipedUser = u;
    notifyListeners();
  }

  bool _fetchingData = false;

  bool get fetchingData => _fetchingData;

  set fetchingData(bool f) {
    if (_fetchingData && !f) {
      _recentlyFetchedCount = _users.length;
    }
    _fetchingData = f;
    notifyListeners();
  }

  void loadData (AppUser currentUser) {
    print("fetching");
    fetchingData = true;
    FireStoreUtils.getFleekUsers(currentUser, this);
  }

  void addUser(AppUser user) {
    if (_users.where((u) => u.userID == user.userID).isNotEmpty) {
      return;
    }
    _streamController.add(user);
    _users.add(user);
    print("user count: ${_users.length}");
    notifyListeners();
  }

  void removeUser(AppUser user) {
    if (user == null || user.userID == null || user.userID.isEmpty) {
      return;
    }
    _users.removeWhere((a) => a.userID == user.userID);
    notifyListeners();
  }

  void undoLeftSwipe(SearchInterest searchInterest) async {
    if (_previousLeftSwipedUser == null) {
      return;
    }
    var id = _previousLeftSwipedUser.userID;
    _users.insert(0, _previousLeftSwipedUser);
    _previousLeftSwipedUser = null;
    notifyListeners();
    await FireStoreUtils.undo(id, searchInterest);
  }

}