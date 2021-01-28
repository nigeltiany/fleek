import 'package:cloud_firestore/cloud_firestore.dart';

class Swipe {
  String id = '';
  String swiperUserID = '';
  String forUserID = '';
  bool hasBeenSeen = false;
  String type = 'dislike';
  Timestamp createdAt = Timestamp.now();
  Timestamp created_at = Timestamp.now();

  Swipe({
    this.id,
    this.swiperUserID,
    this.forUserID,
    this.createdAt,
    this.created_at,
    this.hasBeenSeen,
    this.type,
  });

  factory Swipe.fromJson(Map<String, dynamic> parsedJson) {
    return Swipe(
      id: parsedJson['id'] ?? "",
      swiperUserID: parsedJson['swiperUserID'] ?? "",
      forUserID: parsedJson['forUserID'] ?? '',
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      created_at: parsedJson['created_at'] ?? Timestamp.now(),
      hasBeenSeen: parsedJson['hasBeenSeen'] ?? false,
      type: parsedJson['type'] ?? 'dislike'
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      "swiperUserID": this.swiperUserID,
      "forUserID": this.forUserID,
      "created_at": this.created_at,
      "createdAt": this.createdAt,
      'hasBeenSeen': this.hasBeenSeen,
      'type': this.type
    };
  }
}
