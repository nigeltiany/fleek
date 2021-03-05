import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;

enum FlagReason {
  ABUSIVE_BEHAVIOR,
  NUDITY,
  SCAM,
  SALE_OF_DRUGS,
  SEX_SERVICES,
  UNDER_AGE,
  GUT_FEELING
}

extension FlagReasonToString on FlagReason {
  String toFirebaseString() {
    return this.toString().split('.').last;
  }
}

FlagReason flagReasonFromFirebaseString(String pref) {
  for (FlagReason option in FlagReason.values) {
    if (option.toFirebaseString() == pref) {
      return option;
    }
  }
  return FlagReason.GUT_FEELING;
}

class Flag {

  String flaggedBy;
  List<FlagReason> reasons;
  Firestore.Timestamp createdAt = Firestore.Timestamp.now();

  Flag({
    this.flaggedBy,
    this.reasons,
    this.createdAt,
  });

  factory Flag.fromJson(Map<String, dynamic> parsedJson) {
    Set<FlagReason> reasons = Set<FlagReason>();
    var reasonsData = ((parsedJson["reasons"] ?? []) as List<dynamic>);
    reasonsData.forEach((reason) {
      reasons.add(flagReasonFromFirebaseString(reason));
    });
    return Flag(
      flaggedBy: parsedJson["flaggedBy"] ?? "",
      reasons: reasons.toList(growable: false),
      createdAt: parsedJson["createdAt"],
    );
  }

  Map<String, dynamic> toJson() {
    List<String> reasons = [];
    this.reasons.forEach((reason) {
      reasons.add(reason.toFirebaseString());
    });
    return {
      "flaggedBy": this.flaggedBy,
      "createdAt": this.createdAt,
      "reasons": reasons
    };
  }

}