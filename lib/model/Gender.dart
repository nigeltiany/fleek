enum Gender {
  MALE,
  FEMALE,
  UNKNOWN
}

extension GenderToString on Gender {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

Gender genderFromFirebaseString(String pref) {
  for (Gender option in Gender.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return Gender.UNKNOWN;
}

enum GenderPreference {
  MALE,
  FEMALE,
  ALL
}

extension GenderPreferenceToString on GenderPreference {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

GenderPreference genderPreferenceFromFirebaseString(String pref) {
  for (GenderPreference option in GenderPreference.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return GenderPreference.ALL;
}
