import 'package:dating/model/Gender.dart';
import 'package:dating/model/SearchInterests.dart';
import 'package:flutter/foundation.dart';

class Settings with ChangeNotifier {

  bool _pushNewMessages = true;
  bool _pushNewMatchesEnabled = true;
  GenderPreference _genderPreference;
  Gender _gender;
  SearchInterest _searchInterest;
  double _distanceRadius = double.infinity;
  bool _showMe = false;

  Settings();

  factory Settings.fromJson(Map<dynamic, dynamic> parsedJson) {
    return Settings()
      ..pushNewMessages = parsedJson['pushNewMessages'] ?? true
      ..pushNewMatchesEnabled = parsedJson['pushNewMatchesEnabled'] ?? true
      ..genderPreference = genderPreferenceFromFirebaseString(parsedJson['genderPreference']) ?? GenderPreference.FEMALE
      ..searchInterest = searchInterestFromFirebaseString(parsedJson['searchInterest']) ?? SearchInterest.DATES
      ..gender = genderFromFirebaseString(parsedJson['gender']) ?? Gender.MALE
      ..distanceRadius = parsedJson['distanceRadius'] is double ? parsedJson['distanceRadius'] : double.infinity
      ..showMe = parsedJson['showMe'] ?? true;
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNewMessages': this.pushNewMessages,
      'pushNewMatchesEnabled': this.pushNewMatchesEnabled,
      'genderPreference': this.genderPreference.toFirebaseString(),
      'searchInterest': this.searchInterest.toFirebaseString(),
      'gender': this.gender.toFirebaseString(),
      'distanceRadius': this.distanceRadius,
      'showMe': this.showMe
    };
  }

  bool get pushNewMessages => _pushNewMessages;

  set pushNewMessages(bool value) {
    _pushNewMessages = value;
    notifyListeners();
  }

  bool get pushNewMatchesEnabled => _pushNewMatchesEnabled;

  set pushNewMatchesEnabled(bool value) {
    _pushNewMatchesEnabled = value;
    notifyListeners();
  }

  GenderPreference get genderPreference => _genderPreference;

  set genderPreference(GenderPreference value) {
    _genderPreference = value;
    notifyListeners();
  }

  Gender get gender => _gender;

  set gender(Gender value) {
    _gender = value;
    notifyListeners();
  }

  SearchInterest get searchInterest => _searchInterest;

  set searchInterest(SearchInterest value) {
    _searchInterest = value;
    notifyListeners();
  }

  double get distanceRadius => _distanceRadius;

  set distanceRadius(double value) {
    _distanceRadius = value;
    notifyListeners();
  }

  bool get showMe => _showMe;

  set showMe(bool value) {
    _showMe = value;
    notifyListeners();
  }
}