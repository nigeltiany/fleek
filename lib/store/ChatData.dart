import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatData with ChangeNotifier {

  Map<String, Map<String, MessageData>> _conversations;
  StreamSubscription<QuerySnapshot> _currentChatStream;
  List<MessageData> _activeConversationMessages = [];

  ChatData() {
    _conversations = Map<String, Map<String, MessageData>>();
  }

  List<MessageData> get messages => _activeConversationMessages;

  int _sorter (MessageData a, MessageData b) {
    return a.created.compareTo(b.created) * -1;
  }

  void chattingWith(AppUser appUser) {
    var conversationID = normalizedConversationID(FirebaseAuth.instance.currentUser.uid, appUser.userID);
    if (_currentChatStream != null) {
      _currentChatStream.cancel();
    }
    if (_conversations.containsKey(conversationID)) {
      _activeConversationMessages = _conversations[conversationID].values.toList()..sort(_sorter);
    } else {
      _activeConversationMessages = [];
    }
    _getChatMessages(appUser);
  }

  void _addMessage(MessageData messageData) {
    var conversationID = normalizedConversationID(messageData.senderID, messageData.recipientID);
    if (!_conversations.containsKey(conversationID)) {
      _conversations[conversationID] = Map<String, MessageData>();
    } else if (_conversations[conversationID].containsKey(messageData.messageID)) {
      return;
    }
    _conversations[conversationID][messageData.messageID] = messageData;
    _activeConversationMessages.add(messageData);
    notifyListeners();
  }

  _getChatMessages(AppUser matchedUser) async {
    _currentChatStream = FirebaseFirestore.instance
        .collection(CHANNELS)
        .doc(normalizedConversationID(FirebaseAuth.instance.currentUser.uid, matchedUser.userID))
        .collection(THREAD)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .listen((onData) {
      onData.docs.forEach((document) {
        _addMessage(MessageData.fromJson(document.data()));
      });
    });
  }

}