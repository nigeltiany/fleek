import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/Swipe.dart';
import 'package:dating/model/User.dart';

class FleekMatch {
  SwipeSubject match;
  SearchInterest matchInterest;
  bool seen;
  Timestamp createdAt = Timestamp.now();

  FleekMatch({
    this.match,
    this.matchInterest,
    this.createdAt,
    this.seen
  });

  factory FleekMatch.fromJson(Map<String, dynamic> parsedJson) {
    return FleekMatch(
      match: SwipeSubject.fromJson(parsedJson["match"] ?? SwipeSubject.fromUser(AppUser())),
      seen: parsedJson['seen'] ?? '',
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      matchInterest: searchInterestFromFirebaseString(parsedJson['matchInterest']) ?? SearchInterest.DATES
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "match": this.match,
      "matchInterest": this.matchInterest.toFirebaseString(),
      "createdAt": this.createdAt,
      "seen": false
    };
  }
}
