import 'package:cloud_firestore/cloud_firestore.dart';

class SwipeCounter {

  int count = 0;
  Timestamp createdAt = Timestamp.now();

  SwipeCounter({this.count, this.createdAt});

  factory SwipeCounter.fromJson(Map<String, dynamic> parsedJson) {
    return new SwipeCounter(
      count: parsedJson['count'] ?? 0,
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "count": this.count,
      "createdAt": this.createdAt
    };
  }
}
