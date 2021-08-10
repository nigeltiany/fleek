enum ProfileSetupStep {
  NOT_STARTED,
  DEMOGRAPHICS,
  PROFILE_PICTURE,
  PREFERENCES,
  BIO,
  LOCATION,
  COMPLETE,
}

extension ProfileSetupStepToString on ProfileSetupStep {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

ProfileSetupStep profileSetupStepFromFirebaseString(String pref) {
  for (ProfileSetupStep option in ProfileSetupStep.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return ProfileSetupStep.NOT_STARTED;
}

class ProfileSetupStatus {
  ProfileSetupStep step;

  ProfileSetupStatus({this.step});

  factory ProfileSetupStatus.fromJson(Map<dynamic, dynamic> parsedJson) {
    return ProfileSetupStatus(
      step: profileSetupStepFromFirebaseString(parsedJson['step']) ?? ProfileSetupStep.NOT_STARTED,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': this.step.toFirebaseString(),
    };
  }
}
