import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;
import 'package:dating/model/ProfileSettings.dart';
import 'package:dating/model/UserLocation.dart';
import 'package:flutter/foundation.dart';

class AppUser with ChangeNotifier {
  String _email;
  String _firstName;
  String _lastName;
  String _userName;

  Settings _settings;

  String _phoneNumber;
  bool _active = false;
  Firestore.Timestamp _lastOnlineTimestamp = Firestore.Timestamp.now();
  String _userID;
  String _profilePictureURL;
  String _appIdentifier = 'Flutter Dating ${Platform.operatingSystem}';
  String _fcmToken;
  String _publicKey;

  bool _isVip = false;

  //Fleek related fields
  UserLocation _location;
  UserLocation _signUpLocation;
  String _bio;
  String _school;
  int _age;
  List<dynamic> _photos = [];

  //internal use only, don't save to db
  String _milesAway = '0 Miles Away';
  bool _selected = false;

  AppUser();

  copy(AppUser cp) {
    _email = cp.email ?? _email;
    _firstName = cp.firstName ?? _firstName;
    _lastName = cp.lastName ?? _lastName;
    _userName = cp.userName ?? _userName;
    _active = cp.active ?? false;
    _lastOnlineTimestamp = cp.lastOnlineTimestamp;
    _settings = cp.settings ?? _settings;
    _phoneNumber = cp.phoneNumber ?? _phoneNumber;
    _userID = cp.userID ?? _userID;
    _profilePictureURL = cp.profilePictureURL ?? _profilePictureURL;
    _fcmToken = cp.fcmToken ?? _fcmToken;
    _isVip = cp.isVip ?? _isVip;

    //dating app related fields
    _location = cp.location ?? _location;
    _signUpLocation = cp.signUpLocation ?? _signUpLocation;
    _school = cp.school ?? _school;
    _age = cp.age ?? _age;
    _bio = cp.bio ?? _bio;
    _photos = cp._photos ?? _bio;
    notifyListeners();
  }

  String fullName() {
    return '$firstName $lastName';
  }

  factory AppUser.fromJson(Map<String, dynamic> parsedJson) {
    return AppUser()
      ..email = parsedJson['email'] ?? ''
      ..firstName = parsedJson['firstName'] ?? ''
      ..lastName = parsedJson['lastName'] ?? ''
      ..userName = parsedJson['userName'] ?? ''
      ..active = parsedJson['active'] ?? false
      ..lastOnlineTimestamp = parsedJson['lastOnlineTimestamp']
      ..settings = Settings.fromJson(parsedJson['settings'] ?? Settings().toJson())
      ..phoneNumber = parsedJson['phoneNumber'] ?? ''
      ..userID = parsedJson['id'] ?? parsedJson['userID'] ?? ''
      ..profilePictureURL = parsedJson['profilePictureURL'] ?? ''
      ..fcmToken = parsedJson['fcmToken'] ?? ''
      ..isVip = parsedJson['isVip' ?? false]
      ..publicKey = parsedJson['publicKey'] // allow null

      //dating app related fields
      ..location = UserLocation.fromJson(parsedJson['location'] ?? UserLocation().toJson())
      ..signUpLocation = UserLocation.fromJson(parsedJson['signUpLocation'] ?? UserLocation().toJson())
      ..school = parsedJson['school'] ?? 'N/A'
      ..age = parsedJson['age'] ?? null
      ..bio = parsedJson['bio'] ?? 'N/A'
      ..photos = parsedJson['photos'] ?? [].cast<String>();
  }

  Map<String, dynamic> toJson() {
    photos.toList().removeWhere((element) => element == null);
    return {
      "email": this.email,
      "firstName": this.firstName,
      "lastName": this.lastName,
      "userName": this.userName,
      "settings": this.settings != null ? this.settings.toJson() : Settings().toJson(),
      "phoneNumber": this.phoneNumber,
      "id": this.userID,
      'active': this.active,
      'lastOnlineTimestamp': this.lastOnlineTimestamp,
      "profilePictureURL": this.profilePictureURL,
      'appIdentifier': this.appIdentifier,
      'fcmToken': this.fcmToken,
      'isVip': this.isVip,

      // Do NOT write the public key
      //'publicKey': this.publicKey,

      //tinder related fields
      'showMe': this.settings != null ? this.settings.showMe : false,
      'location': this.location != null ? this.location.toJson() : UserLocation().toJson(),
      'signUpLocation': this.signUpLocation != null ? this.signUpLocation.toJson() : UserLocation().toJson(),
      'bio': this.bio,
      'school': this.school,
      'age': this.age,
      'photos': this.photos,
    };
  }

  String get email => _email;

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  String get firstName => _firstName;

  set firstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  String get lastName => _lastName;

  set lastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  String get userName => _userName;

  set userName(String value) {
    _userName = value;
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

  String get phoneNumber => _phoneNumber;

  set phoneNumber(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  bool get active => _active;

  set active(bool value) {
    _active = value;
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

  String get appIdentifier => _appIdentifier;

  set appIdentifier(String value) {
    _appIdentifier = value;
    notifyListeners();
  }

  String get fcmToken => _fcmToken;

  set fcmToken(String value) {
    _fcmToken = value;
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

  int get age => _age;

  set age(int value) {
    _age = value;
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
