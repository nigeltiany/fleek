import 'dart:async';

import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:flutter/foundation.dart';

class FleekData with ChangeNotifier {

  static int MAX_FETCH_COUNT = 25;

  StreamController<AppUser> _streamController;

  Map<SearchInterest, Set<String>> _recentlyRemovedUserIDs;

  Stream<AppUser> _stream;
  Stream<AppUser> get stream => _stream;

  int _recentlyFetchedCount;

  int get recentlyFetchedCount => _recentlyFetchedCount;

  void clean() {
    _streamController.close();
  }
  
  FleekData () {
    _recentlyRemovedUserIDs = Map<SearchInterest, Set<String>>();
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
    fetchingData = true;
    FireStoreUtils.getFleekUsers(currentUser, this);
  }

  void _populateRecentlyViewed(SearchInterest searchInterest, String userID) {
    if (!_recentlyRemovedUserIDs.containsKey(searchInterest)) {
      _recentlyRemovedUserIDs[searchInterest] = Set<String>();
    }
    _recentlyRemovedUserIDs[searchInterest].add(userID);
  }

  bool seenRecently (AppUser user, SearchInterest searchInterest) {
    if (!_recentlyRemovedUserIDs.containsKey(searchInterest)) {
      return false;
    }
    return _recentlyRemovedUserIDs[searchInterest].contains(user.userID);
  }

  void addUser(AppUser user, SearchInterest searchInterest) {
    if (seenRecently(user, searchInterest)) {
      return;
    }
    if (_users.isNotEmpty && _users.firstWhere((u) => u.userID == user.userID, orElse: () => null) != null) {
      return;
    }
    _streamController.add(user);
    _users.add(user);
    notifyListeners();
  }

  void removeAllUsers() {
    _users.removeRange(0, _users.length);
    notifyListeners();
  }

  void removeUser(AppUser user, SearchInterest searchInterest) {
    if (user == null || user.userID == null || user.userID.isEmpty) {
      return;
    }
    _populateRecentlyViewed(searchInterest, user.userID);
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