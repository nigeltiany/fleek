import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/constants.dart';
import 'package:dating/model/MessageData.dart';
import 'package:dating/model/User.dart';
import 'package:dating/services/helper.dart';
import 'package:dating/store/Store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatData with ChangeNotifier implements DataStore {

  static int MAX_FETCH_COUNT = 25;
  
  Map<String, Map<String, MessageData>> _conversations;
  StreamSubscription<QuerySnapshot> _currentChatStream;
  List<MessageData> _activeConversationMessages = [];

  Map<String, bool> _fetchState;
  StreamController<bool> _fetchStateController;
  Stream _fetchStateStream;

  MessageData _earliestFirstMessage;
  StreamController<bool> _chatHasMoreController;
  Stream _chatHasMoreStateStream;

  AppUser _chattingWith;

  ChatData() {
    _conversations = Map<String, Map<String, MessageData>>();

    _fetchState = Map<String, bool>();
    _fetchStateController = StreamController<bool>();
    _fetchStateStream = _fetchStateController.stream.asBroadcastStream();

    _chatHasMoreController = StreamController<bool>();
    _chatHasMoreStateStream = _chatHasMoreController.stream.asBroadcastStream();
  }

  List<MessageData> get messages => _activeConversationMessages;
  Stream<bool> get fetchStateStream => _fetchStateStream;
  Stream<bool> get chatHasMoreStateStream => _chatHasMoreStateStream;

  int _sorter (MessageData a, MessageData b) {
    return a.created.compareTo(b.created) * -1;
  }
  
  String _conversationID(AppUser matchedUser) {
    return normalizedConversationID(FirebaseAuth.instance.currentUser.uid, matchedUser.userID);
  }

  void chattingWith(AppUser appUser) {
    if (_chattingWith == appUser) {
      return;
    }
    _chattingWith = appUser;
    var conversationID = _conversationID(appUser);
    if (_currentChatStream != null) {
      _currentChatStream.cancel();
    }
    if (_conversations.containsKey(conversationID)) {
      _activeConversationMessages = _conversations[conversationID].values.toList()..sort(_sorter);
    } else {
      _activeConversationMessages = [];
    }
    _earliestFirstMessage = null;
    _setFetchState(appUser, false);
    _getListenToMessages(appUser, fetchPrevious: _activeConversationMessages.length < MAX_FETCH_COUNT);
  }

  void activeChatDone () {
    _earliestFirstMessage = null;
    _chattingWith = null;
    if (_currentChatStream != null) {
      _currentChatStream.cancel();
    }
  }

  void _addMessage(MessageData messageData) {
    var conversationID = normalizedConversationID(messageData.senderID, messageData.recipientID);
    if (!_conversations.containsKey(conversationID)) {
      _conversations[conversationID] = Map<String, MessageData>();
    } else if (_conversations[conversationID].containsKey(messageData.messageID)) {
      return;
    }
    _conversations[conversationID][messageData.messageID] = messageData;
    if (_activeConversationMessages.isEmpty) {
      _activeConversationMessages.add(messageData);
    } else {
      if (_activeConversationMessages.first.created != null && messageData.created != null) {
        if (messageData.created.compareTo(_activeConversationMessages.first.created) >= 0) {
          _activeConversationMessages.insert(0, messageData);
        } else {
          _activeConversationMessages.add(messageData);
        }
      } else {
        _activeConversationMessages.add(messageData);
      }
    }
    notifyListeners();
  }

  Query _fetchQuery(AppUser matchedUser) {
    return FirebaseFirestore.instance
      .collection(MATCH_CONVERSATIONS)
      .doc(_conversationID(matchedUser))
      .collection(CONVERSATION_MESSAGES)
      .orderBy('createdAt', descending: true);
  }
  
  _setFetchState (AppUser chatWith, bool fetching) {
    var conversationID = _conversationID(chatWith);
    _fetchState[conversationID] = fetching;
    _fetchStateController.add(fetching);

    if (!fetching) {
      if (_earliestFirstMessage != null) {
        var keys = _conversations[conversationID].keys.toList();
        if (_activeConversationMessages.length - keys.indexOf(_earliestFirstMessage.messageID) >= 25) {
          _chatHasMoreController.add(true);
        } else {
          _chatHasMoreController.add(false);
        }
      }
    } else if (_activeConversationMessages.isNotEmpty) {
      _earliestFirstMessage = _activeConversationMessages.last;
    }
  }

  void scrollFetch(AppUser matchedUser) async {
    if (_activeConversationMessages == null || matchedUser == null) return;
    if (_fetchState[_conversationID(matchedUser)]) return;

    var query = _fetchQuery(matchedUser).limit(MAX_FETCH_COUNT);

    if (_activeConversationMessages.isNotEmpty && _activeConversationMessages.last.created != null) {
      query = query.where("createdAt", isLessThan: _activeConversationMessages.last.created);
    }

    _setFetchState(matchedUser, true);
    var data = await query.get();
    data.docs.forEach((document) {
      _addMessage(MessageData.fromJson(document.data()));
    });
    _setFetchState(matchedUser, false);
  }

  _getListenToMessages(AppUser matchedUser, { bool fetchPrevious = true }) async {
    var query = _fetchQuery(matchedUser);

    if (fetchPrevious) {
      if (_fetchState[_conversationID(matchedUser)]) return;
      _setFetchState(matchedUser, true);
      var data = await query.limit(MAX_FETCH_COUNT).get();
      data.docs.forEach((document) {
        _addMessage(MessageData.fromJson(document.data()));
      });
      _setFetchState(matchedUser, false);
    }

    _currentChatStream = query.limit(1).snapshots().listen((onData) {
      onData.docs.forEach((document) {
        _addMessage(MessageData.fromJson(document.data()));
      });
    });
  }

  @override
  void clearData() {
    _conversations = Map<String, Map<String, MessageData>>();
    _fetchState = Map<String, bool>();
    notifyListeners();
  }

  @override
  void closeFirebaseStreams() {
    _currentChatStream?.cancel();
    _currentChatStream = null;
  }

}