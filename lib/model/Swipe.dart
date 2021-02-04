import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:flutter/cupertino.dart';

class Swipe {
  String id = '';
  String swiperUserID = '';
  String forUserID = '';
  bool hasBeenSeen = false;
  String type = 'dislike';
  SearchInterest searchInterest;
  Timestamp createdAt = Timestamp.now();

  Swipe({
    this.id,
    this.swiperUserID,
    this.forUserID,
    this.createdAt,
    this.hasBeenSeen,
    this.type,
    @required this.searchInterest,
  });

  factory Swipe.fromJson(Map<String, dynamic> parsedJson) {
    return Swipe(
      id: parsedJson['id'] ?? "",
      swiperUserID: parsedJson['swiperUserID'] ?? "",
      forUserID: parsedJson['forUserID'] ?? '',
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      hasBeenSeen: parsedJson['hasBeenSeen'] ?? false,
      type: parsedJson['type'] ?? 'dislike',
      searchInterest: searchInterestFromFirebaseString(parsedJson['searchInterest']) ?? SearchInterest.DATES
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': this.id,
      "swiperUserID": this.swiperUserID,
      "forUserID": this.forUserID,
      "createdAt": this.createdAt,
      'hasBeenSeen': this.hasBeenSeen,
      'type': this.type,
      'searchInterest': this.searchInterest.toFirebaseString(),
    };
  }
}
