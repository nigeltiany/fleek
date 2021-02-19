import 'package:cloud_firestore/cloud_firestore.dart';

class MessageData {

  String messageID = '';
  Url url = Url(url: '', mime: '');
  Content content = Content(content: {});
  Timestamp created = Timestamp.now();
  String recipientProfilePictureURL = '';
  String recipientID = '';
  String senderUsername = '';
  String senderProfilePictureURL = '';
  String senderID = '';
  Url videoThumbnail = Url(url: '', mime: '');

  MessageData({
    this.messageID,
    this.url,
    this.content,
    this.created,
    this.recipientProfilePictureURL,
    this.recipientID,
    this.senderUsername,
    this.senderProfilePictureURL,
    this.senderID,
    this.videoThumbnail
  });

  factory MessageData.fromJson(Map<String, dynamic> parsedJson) {

    Map<String, String> content = Map<String, String>();
    if (parsedJson.containsKey('content')) {
      content = Map<String, dynamic>.from(parsedJson["content"]).map((key, value) => MapEntry(key, value?.toString()));
    }

    return new MessageData(
      messageID: parsedJson['id'] ?? parsedJson['messageID'] ?? '',
      url: Url.fromJson(parsedJson['url'] ?? Url().toJson()),
      content: Content(content: content),
      created: parsedJson['createdAt'] ?? parsedJson['created'] ?? Timestamp.now(),
      recipientProfilePictureURL: parsedJson['recipientProfilePictureURL'] ?? '',
      recipientID: parsedJson['recipientID'] ?? '',
      senderUsername: parsedJson['senderUsername'] ?? '',
      senderProfilePictureURL: parsedJson['senderProfilePictureURL'] ?? '',
      senderID: parsedJson['senderID'] ?? '',
      videoThumbnail: Url.fromJson(parsedJson['videoThumbnail'] ?? Url().toJson()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.messageID,
      "url": this.url?.toJson(),
      "content": this.content.toJson(),
      "createdAt": this.created,
      'recipientProfilePictureURL': this.recipientProfilePictureURL,
      "recipientID": this.recipientID,
      "senderUsername": this.senderUsername,
      "senderProfilePictureURL": this.senderProfilePictureURL,
      "senderID": this.senderID,
      "videoThumbnail": this.videoThumbnail?.toJson()
    };
  }
}

class Url {
  String mime = '';
  String url = '';

  Url({this.mime, this.url});

  factory Url.fromJson(Map<dynamic, dynamic> parsedJson) {
    return Url(mime: parsedJson['mime'] ?? '', url: parsedJson['url'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'mime': this.mime, 'url': this.url};
  }
}

class Content {

  Map<String, String> content;

  Content({ this.content });

  factory Content.fromJson(Map<String, String> parsedJson) {
    return Content(content: parsedJson);
  }

  Map<String, dynamic> toJson() {
    return content;
  }

}