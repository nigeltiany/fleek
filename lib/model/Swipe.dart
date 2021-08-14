import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dating/model/ProfileSettings.dart' as Profile;
import 'package:dating/model/SearchInterests.dart';
import 'package:dating/model/User.dart';
import 'package:flutter/material.dart';

enum SwipeType {
  LIKE,
  PASS,
  SUPER_LIKE
}

extension SwipeTypeToString on SwipeType {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

SwipeType swipeTypeFromFirebaseString(String pref) {
  for (SwipeType option in SwipeType.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return SwipeType.LIKE;
}

class SwipeSubject implements IdentifiableUser, UserWithImage {

  final AppUser _appUser;

  @override
  String get userID => _appUser.userID;

  String get userName => _appUser.userName;
  String get profilePictureURL => _appUser.profilePictureURL;
  Profile.Settings get settings => _appUser.settings;

  SwipeSubject.fromUser(this._appUser);

  Map<String, dynamic> toJson() {
    return {
      "id": _appUser.userID,
      "userName": _appUser.userName,
      "profilePictureURL": _appUser.profilePictureURL,
      "settings": _appUser.settings.toJson(),
    };
  }

  factory SwipeSubject.fromJson(Map<String, dynamic> parsedJson) {
    return SwipeSubject.fromUser(
      AppUser()
        ..userID = parsedJson['id'] ?? ''
        ..userName = parsedJson['userName'] ?? ''
        ..profilePictureURL = parsedJson['profilePictureURL'] ?? ''
        ..settings = Profile.Settings.fromJson(parsedJson['settings'] ?? Profile.Settings().toJson())
    );
  }

  @override
  set profilePictureURL(String url) {
    _appUser.profilePictureURL = url;
  }

}

class Swipe {

  String id = '';
  SwipeSubject swiper;
  SwipeSubject subject;
  bool hasBeenSeen = false;
  SwipeType type = SwipeType.PASS;
  SearchInterest searchInterest;
  Timestamp createdAt = Timestamp.now();

  Swipe({
    this.id,
    this.swiper,
    this.subject,
    this.createdAt,
    this.hasBeenSeen,
    this.type,
    @required this.searchInterest,
  });

  factory Swipe.fromJson(Map<String, dynamic> parsedJson) {
    return Swipe(
      id: parsedJson['id'] ?? "",
      swiper: SwipeSubject.fromJson(parsedJson["swiper"] ?? SwipeSubject.fromUser(AppUser())),
      subject: SwipeSubject.fromJson(parsedJson["subject"] ?? SwipeSubject.fromUser(AppUser())),
      createdAt: parsedJson['createdAt'] ?? Timestamp.now(),
      hasBeenSeen: parsedJson['hasBeenSeen'] ?? false,
      type: swipeTypeFromFirebaseString(parsedJson['type']) ?? SwipeType.LIKE,
      searchInterest: searchInterestFromFirebaseString(parsedJson['searchInterest']) ?? SearchInterest.DATES
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": this.id,
      "swiper": this.swiper.toJson(),
      "subject": this.subject.toJson(),
      "createdAt": this.createdAt,
      "hasBeenSeen": this.hasBeenSeen,
      "type": this.type.toFirebaseString(),
      "searchInterest": this.searchInterest.toFirebaseString(),
    };
  }
}
