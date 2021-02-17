import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/ConversationModel.dart';
import 'package:dating/model/User.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConversationData with ChangeNotifier {

  Map<String, AppUser> _conversationUsers;
  Map<String, ConversationModel> _conversation;
  // ignore: cancel_subscriptions
  StreamSubscription<QuerySnapshot> _streamSubscription;

  ConversationData() {

    _conversation = Map<String, ConversationModel>();
    _conversationUsers = Map<String, AppUser>();

    FirebaseAuth.instance.authStateChanges().where((User u) => u != null).listen((User user) {
      if (_streamSubscription != null) return;
      _getConversations(user.uid);
    });

  }

  List<ConversationModel> get conversations => List.unmodifiable(_conversation.values);

  void _addConversation(ConversationModel conversationModel) {
    _conversation[conversationModel.id] = conversationModel;
    notifyListeners();
  }

  bool hasUserID(String userID) {
    return _conversationUsers.containsKey(userID);
  }

  AppUser getUser(String userID) {
    return _conversationUsers[userID];
  }

  void addConversationUser(AppUser appUser) {
    if (_conversationUsers.containsKey(appUser.userID)) return;
    _conversationUsers[appUser.userID] = appUser;
    notifyListeners();
  }

  _getConversations(String userID) async {
    _streamSubscription = FirebaseFirestore.instance
      .collection(CHANNELS)
      .where('participantIDs', arrayContains: userID)
      .orderBy('lastMessageDate', descending: true)
      .snapshots().listen((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          _addConversation(ConversationModel.fromJson(doc.data()));
        });
    });
  }

}