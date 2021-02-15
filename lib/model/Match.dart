import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:flutter/cupertino.dart';

class FleekMatch {
  String matchUserID;
  SearchInterest matchInterest;
  bool seen;
  Timestamp createdAt = Timestamp.now();

  FleekMatch({
    this.matchUserID,
    this.matchInterest,
    this.createdAt,
    this.seen
  });

  factory FleekMatch.fromJson(Map<String, dynamic> parsedJson) {
    return FleekMatch(
      matchUserID: parsedJson['matchUserID'] ?? "",
      seen: parsedJson['seen'] ?? '',
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      matchInterest: searchInterestFromFirebaseString(parsedJson['matchInterest']) ?? SearchInterest.DATES
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "matchUserID": this.matchUserID,
      "matchInterest": this.matchInterest.toFirebaseString(),
      "createdAt": this.createdAt,
      "seen": false
    };
  }
}
