import 'package:dating/model/ChatModel.dart';

import 'ConversationModel.dart';
import 'User.dart';

class HomeConversationModel {

  bool isGroupChat = false;
  List<AppUser> members = [];
  Encrypter recipientEncrypter;
  ConversationModel conversationModel = ConversationModel();

  HomeConversationModel({
    this.isGroupChat,
    this.members,
    this.conversationModel,
    this.recipientEncrypter
  });

}
