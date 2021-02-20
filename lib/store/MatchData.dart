import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Match.dart';
import 'package:dating/model/User.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MatchData with ChangeNotifier {

  Map<String, FleekMatch> _matchDataStore;
  List<FleekMatch> _matches;
  List<FleekMatch> get matches => _matches;

  StreamController<FleekMatch> _matchController;
  Stream<FleekMatch> _matchStream;

  StreamSubscription<QuerySnapshot> _streamSubscription;
  Stream<FleekMatch> get matchStream => _matchStream;

  MatchData(ConversationData conversationData) {
    _matches = List<FleekMatch>();
    _matchDataStore = Map<String, FleekMatch>();
    _matchController = StreamController<FleekMatch>();
    _matchStream = _matchController.stream.asBroadcastStream();

    FirebaseAuth.instance.authStateChanges().where((User u) => u != null).listen((User user) {
      if (_streamSubscription == null) {
        _getMatches();
        _listenForMatches(user);
      }
    });
  }

  void setMatchAsSeen (FleekMatch match) async {
    await FirebaseFirestore.instance
      .collection(MATCHES)
      .doc(FirebaseAuth.instance.currentUser.uid)
      .collection('matches')
      .doc(match.match.userID)
      .set((match..seen = true).toJson(), SetOptions(merge: true));
  }

  void removeCachedMatch(IdentifiableUser user) {
    _matchDataStore.removeWhere((key, _) => key == user.userID);
    _matches.removeWhere((match) => match.match.userID == user.userID);
    notifyListeners();
  }

  void _addMatch(FleekMatch fleekMatch) {
    if (_matchDataStore.containsKey(fleekMatch.match.userID)) {
      return;
    }
    _matchDataStore[fleekMatch.match.userID] = fleekMatch;
    _matchController.add(fleekMatch);
    _matches.add(fleekMatch);
    notifyListeners();
  }

  Query _matchQuery() {
    return FirebaseFirestore.instance
      .collection(MATCHES)
      .doc(FirebaseAuth.instance.currentUser.uid)
      .collection('matches')
      .orderBy('createdAt', descending: true);
  }

  _getMatches() async {
    var ms = await _matchQuery().get();
    ms.docs.forEach((m) {
      _addMatch(FleekMatch.fromJson(m.data()));
    });
  }

  _listenForMatches(User user) {
    _streamSubscription = _matchQuery().limit(1).snapshots().listen((querySnapshot) {
      if (querySnapshot.docs.isEmpty && querySnapshot.docChanges.isNotEmpty) {
        _matchDataStore.removeWhere((key, _) => key == querySnapshot.docChanges.first.doc.id);
        _matches.removeWhere((match) => match.match.userID == querySnapshot.docChanges.first.doc.id);
        notifyListeners();
      } else {
        querySnapshot.docs.forEach((doc) {
          _addMatch(FleekMatch.fromJson(doc.data()));
        });
      }
    });
  }

}