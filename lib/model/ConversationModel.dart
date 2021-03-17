import 'package:cloud_firestore/cloud_firestore.dart';

import 'MessageData.dart';

class ConversationModel {
  String id = '';
  String creatorID = '';
  Timestamp createdAt;
  Timestamp lastMessageDate = Timestamp.now();
  Map<String, Timestamp> lastViewedDate = {};
  Content lastMessage = Content(content: {});
  List<dynamic> participantIDs = [];

  ConversationModel({
    this.id,
    this.createdAt,
    this.creatorID,
    this.lastMessage,
    this.lastMessageDate,
    this.participantIDs,
    this.lastViewedDate
  });

  factory ConversationModel.fromJson(Map<String, dynamic> parsedJson) {
    Map<String, String> content = Map<String, String>();
    if (parsedJson.containsKey('lastMessage')) {
      content = Map<String, dynamic>.from(parsedJson["lastMessage"]).map((key, value) => MapEntry(key, value?.toString()));
    }

    Map<String, Timestamp> lastViewTimestamps = Map<String, Timestamp>();
    if (parsedJson.containsKey('lastViewedDate')) {
      lastViewTimestamps = Map<String, dynamic>.from(parsedJson["lastViewedDate"]).map((key, value) => MapEntry(key, value as Timestamp));
    }

    return ConversationModel(
      id: parsedJson['id'] ?? '',
      creatorID: parsedJson['creatorID'] ?? parsedJson['creator_id'] ?? '',
      lastMessage: Content(content: content),
      createdAt: parsedJson['createdAt'] ?? null,
      lastMessageDate: parsedJson['lastMessageDate'] ?? Timestamp.now(),
      participantIDs: parsedJson['participantIDs'],
      lastViewedDate: lastViewTimestamps
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "creatorID": this.creatorID,
      "createdAt": this.createdAt,
      "lastMessage": this.lastMessage.toJson(),
      "lastMessageDate": this.lastMessageDate,
      "participantIDs": this.participantIDs,
      "lastViewedDate": this.lastViewedDate
    };
  }
}
