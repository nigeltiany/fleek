import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/SwipeCounterModel.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/FirebaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FleekData with ChangeNotifier {

  static int MAX_FETCH_COUNT = 25;

  static int HOURS_SWIPE_THROTTLE = 4;

  StreamController<AppUser> _streamController;

  Map<SearchInterest, Set<String>> _recentlyRemovedUserIDs;

  Stream<AppUser> _stream;
  Stream<AppUser> get stream => _stream;

  int _recentlyFetchedCount;

  SwipeCounter _swipeCounter;

  SwipeCounter get swipeCounter => _swipeCounter;

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

  SwipeCounter get _defaultCounter {
    return SwipeCounter(
      count: 0,
      createdAt: Timestamp.now(),
    );
  }

  void resetSwipeCounter() {
    _swipeCounter = _defaultCounter;
    notifyListeners();
  }

  void loadData (AppUser currentUser) {
    fetchingData = true;
    if (_swipeCounter == null) {
      FireStoreUtils.getSwipeCounter().then((counter) {
        _swipeCounter = counter;
        notifyListeners();
        FireStoreUtils.getFleekUsers(currentUser, this);
      }).catchError((_) {
        _swipeCounter = _defaultCounter;
        notifyListeners();
        FireStoreUtils.getFleekUsers(currentUser, this);
      });
    } else {
      FireStoreUtils.getFleekUsers(currentUser, this);
    }
  }

  void incrementSwipeCount() {
    if (_swipeCounter == null) {
      _swipeCounter = _defaultCounter;
    }
    _swipeCounter.count += 1;
    notifyListeners();
    FireStoreUtils.firestore.collection(SWIPE_COUNT).doc(FirebaseAuth.instance.currentUser.uid).set(_swipeCounter.toJson(), SetOptions(merge: true));
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

  bool get maxHourlyCountExceeded {
    if (_swipeCounter == null) {
      _swipeCounter = _defaultCounter;
    }
    if (_swipeCounter.count < 40) {
      return false;
    }
    DateTime from = DateTime.fromMillisecondsSinceEpoch(_swipeCounter.createdAt.millisecondsSinceEpoch);
    Duration diff = from.difference(DateTime.now()).abs();
    if (diff.inHours >= HOURS_SWIPE_THROTTLE) {
      return false;
    }
    return true;
  }

}