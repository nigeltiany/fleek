import 'MessageData.dart';
import 'User.dart';

class ChatModel {
  List<MessageData> messages = [];
  AppUser matchedUser;
  Encrypter recipientEncrypter;
}

typedef Encrypter = Future<String> Function(String message);