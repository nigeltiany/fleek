import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;
import 'package:dating/model/ProfileSettings.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:flutter/foundation.dart';

abstract class IdentifiableUser {
  String get userID;
}

class AppUser with ChangeNotifier implements IdentifiableUser {

  String _userName;
  Firestore.Timestamp _birthDate;

  Settings _settings;

  Firestore.Timestamp _lastOnlineTimestamp = Firestore.Timestamp.now();
  String _userID;
  String _profilePictureURL;
  String _platform = '${Platform.operatingSystem}';
  String _publicKey;

  bool _signedIn = false;
  bool _online = false;
  bool _isVip = false;
  bool _developerAccount = kDebugMode;

  //Fleek related fields
  UserLocation _location;
  UserLocation _signUpLocation;
  String _bio;
  String _school;
  String _schoolCode = "002905";
  List<dynamic> _photos = [];

  //internal use only, don't save to db
  String _milesAway = '0 Miles Away';
  bool _selected = false;

  AppUser();

  copy(AppUser cp) {
    _userName = cp.userName ?? _userName;
    _birthDate = cp.birthDate ?? _birthDate;
    _online = cp.online ?? false;
    _signedIn = cp.signedIn ?? false;
    _lastOnlineTimestamp= cp.lastOnlineTimestamp;
    _settings = cp.settings ?? _settings;
    _userID = cp.userID ?? _userID;
    _profilePictureURL = cp.profilePictureURL ?? _profilePictureURL;
    _isVip = cp.isVip ?? _isVip;
    _developerAccount = cp._developerAccount ?? _developerAccount;

    //dating app related fields
    _location = cp.location ?? _location;
    _signUpLocation = cp.signUpLocation ?? _signUpLocation;
    _school = cp.school ?? _school;
    _schoolCode = cp.schoolCode ?? _schoolCode;
    _bio = cp.bio ?? _bio;
    _photos = cp._photos ?? _bio;
    notifyListeners();
  }

  reset () {
    _userName = null;
    _birthDate = null;
    _online = false;
    _settings = Settings();
    _userID = null;
    _profilePictureURL = null;
    _isVip = false;

    //dating app related fields
    _location = null;
    _signUpLocation = null;
    _school = null;
    _schoolCode = "002905"; // A&T
    _bio = null;
    _photos = [];
    notifyListeners();
  }

  factory AppUser.fromJson(Map<String, dynamic> parsedJson) {
    return AppUser()
      ..userName = parsedJson['userName'] ?? ''
      ..birthDate = parsedJson['birthDate']
      ..online = parsedJson['online'] ?? false
      ..signedIn = parsedJson['signedIn'] ?? false
      ..lastOnlineTimestamp = parsedJson['lastOnlineTimestamp']
      ..settings = Settings.fromJson(parsedJson['settings'] ?? Settings().toJson())
      ..userID = parsedJson['id'] ?? ''
      ..profilePictureURL = parsedJson['profilePictureURL'] ?? ''
      ..isVip = parsedJson['isVip' ?? false]
      ..developerAccount = parsedJson['developerAccount' ?? kDebugMode]
      ..publicKey = parsedJson['publicKey'] // allow null

      //dating app related fields
      ..location = UserLocation.fromJson(parsedJson['location'] ?? UserLocation().toJson())
      ..signUpLocation = UserLocation.fromJson(parsedJson['signUpLocation'] ?? UserLocation().toJson())
      ..school = parsedJson['school'] ?? 'North Carolina A&T University'
      ..schoolCode = parsedJson['schoolCode'] ?? '002905'
      ..bio = parsedJson['bio'] ?? 'N/A'
      ..photos = parsedJson['photos'] ?? [].cast<String>();
  }

  Map<String, dynamic> toJson() {
    photos.toList().removeWhere((element) => element == null);
    return {
      "userName": this.userName,
      "birthDate": this.birthDate,
      "settings": this.settings != null ? this.settings.toJson() : Settings().toJson(),
      "id": this.userID,
      'online': this.online,
      'signedIn': this.signedIn,
      'lastOnlineTimestamp': this.lastOnlineTimestamp,
      "profilePictureURL": this.profilePictureURL,
      'platform': this.platform,
      'isVip': this.isVip,
      'developerAccount': this.developerAccount,

      // Do NOT write the public key. NEVER WRITE THE PUBLIC KEY
      //'publicKey': this.publicKey,

      //fleek related fields
      'location': this.location != null ? this.location.toJson() : UserLocation().toJson(),
      'signUpLocation': this.signUpLocation != null ? this.signUpLocation.toJson() : UserLocation().toJson(),
      'bio': this.bio,
      'school': this.school,
      'schoolCode': this.schoolCode,
      'photos': this.photos,
    };
  }

  String get userName => _userName;

  set userName(String value) {
    _userName = value;
    notifyListeners();
  }

  Firestore.Timestamp get birthDate => _birthDate;

  set birthDate(Firestore.Timestamp value) {
    _birthDate = value;
    notifyListeners();
  }

  String get profilePictureURL => _profilePictureURL;

  set profilePictureURL(String value) {
    _profilePictureURL = value;
    notifyListeners();
  }

  Settings get settings => _settings;

  set settings(Settings value) {
    _settings = value;
    notifyListeners();
  }

  bool get online => _online;

  set online(bool value) {
    _online = value;
    notifyListeners();
  }

  bool get signedIn => _signedIn;

  set signedIn(bool value) {
    _signedIn = value;
    notifyListeners();
  }

  bool get developerAccount => _developerAccount;

  set developerAccount(bool value) {
    _developerAccount = value;
    notifyListeners();
  }

  Firestore.Timestamp get lastOnlineTimestamp => _lastOnlineTimestamp;

  set lastOnlineTimestamp(Firestore.Timestamp value) {
    _lastOnlineTimestamp = value;
    notifyListeners();
  }

  String get userID => _userID;

  set userID(String value) {
    _userID = value;
    notifyListeners();
  }

  String get platform => _platform;

  set platform(String value) {
    _platform = value;
    notifyListeners();
  }

  bool get isVip => _isVip;

  set isVip(bool value) {
    _isVip = value;
    notifyListeners();
  }

  UserLocation get location => _location;

  set location(UserLocation value) {
    _location = value;
    notifyListeners();
  }

  UserLocation get signUpLocation => _signUpLocation;

  set signUpLocation(UserLocation value) {
    _signUpLocation = value;
    notifyListeners();
  }

  String get bio => _bio;

  set bio(String value) {
    _bio = value;
    notifyListeners();
  }

  String get school => _school;

  set school(String value) {
    _school = value;
    notifyListeners();
  }

  String get schoolCode => _schoolCode;

  set schoolCode(String value) {
    _schoolCode = value;
    notifyListeners();
  }

  List<dynamic> get photos => _photos;

  set photos(List<dynamic> value) {
    _photos = value;
    notifyListeners();
  }

  String get milesAway => _milesAway;

  set milesAway(String value) {
    _milesAway = value;
    notifyListeners();
  }

  bool get selected => _selected;

  set selected(bool value) {
    _selected = value;
    notifyListeners();
  }

  String get publicKey => _publicKey;

  set publicKey(String value) {
    _publicKey = value;
    notifyListeners();
  }

}
