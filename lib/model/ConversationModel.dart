import 'package:cloud_firestore/cloud_firestore.dart';

import 'MessageData.dart';

class ConversationModel {
  String id = '';
  String lastSenderID = '';
  Timestamp createdAt;
  Timestamp lastMessageDate = Timestamp.now();
  Content lastMessage = Content(content: {});
  List<dynamic> participantIDs = [];

  ConversationModel({
    this.id,
    this.createdAt,
    this.lastSenderID,
    this.lastMessage,
    this.lastMessageDate,
    this.participantIDs
  });

  factory ConversationModel.fromJson(Map<String, dynamic> parsedJson) {
    Map<String, String> content = Map<String, String>();
    if (parsedJson.containsKey('lastMessage')) {
      content = Map<String, dynamic>.from(parsedJson["lastMessage"]).map((key, value) => MapEntry(key, value?.toString()));
    }

    return ConversationModel(
      id: parsedJson['id'] ?? '',
      lastSenderID: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
      lastMessage: Content(content: content),
      createdAt: parsedJson['createdAt'] ?? null,
      lastMessageDate: parsedJson['lastMessageDate'] ?? Timestamp.now(),
      participantIDs: parsedJson['participantIDs']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "creatorID": this.lastSenderID,
      "createdAt": this.createdAt,
      "lastMessage": this.lastMessage.toJson(),
      "lastMessageDate": this.lastMessageDate,
      "participantIDs": this.participantIDs
    };
  }
}
