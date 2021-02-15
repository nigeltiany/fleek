import 'package:cloud_firestore/cloud_firestore.dart';

class BlockUserModel {
  Timestamp createdAt = Timestamp.now();
  String blocker = '';
  String source = '';
  String type = '';

  BlockUserModel({this.createdAt, this.blocker, this.source, this.type});

  factory BlockUserModel.fromJson(Map<String, dynamic> parsedJson) {
    return new BlockUserModel(
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      blocker: parsedJson['blocker'] ?? '',
      source: parsedJson['source'] ?? '',
      type: parsedJson['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'createdAt': this.createdAt,
      'blocker': this.blocker,
      'source': this.source,
      'type': this.type
    };
  }
}
