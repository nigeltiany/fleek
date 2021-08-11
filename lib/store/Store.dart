import 'package:dating/model/User.dart';
import 'package:dating/store/ChatData.dart';
import 'package:dating/store/ConversationData.dart';
import 'package:dating/store/Data.dart';
import 'package:dating/store/LikeData.dart';
import 'package:dating/store/MatchData.dart';

class Store {

  AppUser _appUser;
  AppUser get appUser => _appUser;

  FleekData _fleekData;
  FleekData get fleekData => _fleekData;

  ChatData _chatData;
  ChatData get chatData => _chatData;

  ConversationData _conversationData;
  ConversationData get conversationData => _conversationData;

  MatchData _matchData;
  MatchData get matchData => _matchData;

  LikeData _likeData;
  LikeData get likeData => _likeData;


  static final Store _singleton = Store._internal();

  factory Store() {
    return _singleton;
  }

  Store._internal() {
    _appUser = AppUser();
    _fleekData = FleekData();
    _chatData = ChatData();
    _conversationData = ConversationData();
    _matchData = MatchData();
    _likeData = LikeData();
  }

  void rebuild() {
    Store._internal();
  }

}

abstract class DataStore {

  void closeFirebaseStreams();
  void clearData();

}