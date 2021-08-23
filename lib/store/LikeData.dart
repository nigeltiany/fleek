import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/store/Store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LikeData with ChangeNotifier implements DataStore {

  Map<String, Swipe> _likesDataStore;
  List<Swipe> _likes;
  List<Swipe> get likes => _likes;

  StreamController<Swipe> _likesController;
  Stream<Swipe> _likesStream;

  StreamSubscription<QuerySnapshot> _streamSubscription;
  Stream<Swipe> get likesStream => _likesStream;

  LikeData() {
    _likes = [];
    _likesDataStore = Map<String, Swipe>();
    _likesController = StreamController<Swipe>();
    _likesStream = _likesController.stream.asBroadcastStream();

    FirebaseAuth.instance.authStateChanges().where((User u) => u != null).listen((User user) {
      if (_streamSubscription == null) {
        _getLikes();
        _listenForLikes(user);
      }
    });
  }

  void _addLike(Swipe swipe) {
    if (_likesDataStore.containsKey(swipe.id)) {
      return;
    }
    _likesDataStore[swipe.id] = swipe;
    _likesController.add(swipe);
    _likes.add(swipe);
    notifyListeners();
  }

  Query _likesQuery() {
    return FirebaseFirestore.instance.collectionGroup(SWIPES_SUB_COLLECTION)
      .where('type', whereIn: [SwipeType.LIKE.toFirebaseString(), SwipeType.SUPER_LIKE.toFirebaseString()])
      .where('subject.id', isEqualTo: FirebaseAuth.instance.currentUser.uid)
      .orderBy('createdAt', descending: true);
  }

  _getLikes() async {
    var ms = await _likesQuery().get();
    ms.docs.forEach((m) {
      _addLike(Swipe.fromJson(m.data()));
    });
  }

  _listenForLikes(User user) {
    _streamSubscription = _likesQuery().snapshots().listen((querySnapshot) {
      if (querySnapshot.docChanges.isNotEmpty) {
        _likesDataStore.removeWhere((key, _) => key == querySnapshot.docChanges.first.doc.id);
        _likes.removeWhere((like) => like.id == querySnapshot.docChanges.first.doc.id);
        querySnapshot.docChanges.forEach((change) {
          _addLike(Swipe.fromJson(change.doc.data()));
        });
        notifyListeners();
      } else {
        querySnapshot.docs.forEach((doc) {
          _addLike(Swipe.fromJson(doc.data()));
        });
      }
      _likes.sort((Swipe a, Swipe b) {
        Timestamp first = (a.createdAt ?? Timestamp.now());
        Timestamp second = (b.createdAt ?? Timestamp.now());
        return first.compareTo(second) * -1;
      });
    });
  }

  @override
  void clearData() {
    _likes = [];
    _likesDataStore = Map<String, Swipe>();
  }

  @override
  void closeFirebaseStreams() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
  }

}