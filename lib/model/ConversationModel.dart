import 'package:cloud_firestore/cloud_firestore.dart';

import 'MessageData.dart';

class ConversationModel {
  String id = '';
  String creatorId = '';
  String name = '';
  Timestamp lastMessageDate = Timestamp.now();
  Content lastMessage = Content(content: {});

  ConversationModel({
    this.id,
    this.creatorId,
    this.lastMessage,
    this.name,
    this.lastMessageDate
  });

  factory ConversationModel.fromJson(Map<String, dynamic> parsedJson) {

    Map<String, String> content = Map<String, String>();
    if (parsedJson.containsKey('lastMessage')) {
      content = Map<String, dynamic>.from(parsedJson["lastMessage"]).map((key, value) => MapEntry(key, value?.toString()));
    }

    return ConversationModel(
      id: parsedJson['id'] ?? '',
      creatorId: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
      lastMessage: Content(content: content),
      name: parsedJson['name'] ?? '',
      lastMessageDate: parsedJson['lastMessageDate'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "creatorID": this.creatorId,
      "lastMessage": this.lastMessage.toJson(),
      "name": this.name,
      "lastMessageDate": this.lastMessageDate,
    };
  }
}
