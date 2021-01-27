import 'MessageData.dart';
import 'User.dart';

class ChatModel {
  List<MessageData> message = [];
  List<AppUser> members = [];
  Encrypter recipientEncrypter;
}

typedef Encrypter = Future<String> Function(String message);