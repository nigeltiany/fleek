import 'package:dating/model/ChatModel.dart';

import 'ConversationModel.dart';
import 'User.dart';

class HomeConversationModel {

  bool isGroupChat = false;
  AppUser matchedUser;
  Encrypter recipientEncrypter;
  ConversationModel conversationModel = ConversationModel();

  HomeConversationModel({
    this.isGroupChat,
    this.matchedUser,
    this.conversationModel,
    this.recipientEncrypter
  });

}
