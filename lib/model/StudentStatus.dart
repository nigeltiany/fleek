import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;

class StudentStatus {

  String verificationID ="";
  bool verified = false;
  Firestore.Timestamp emailedAt = Firestore.Timestamp.now();

  StudentStatus({
    this.verificationID,
    this.verified,
    this.emailedAt,
  });

  factory StudentStatus.fromJson(Map<String, dynamic> parsedJson) {
    return StudentStatus(
      verificationID: parsedJson["verification_id"] ?? "",
      verified: parsedJson["verified"] ?? false,
      emailedAt: parsedJson["emailed_at"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "verification_id": this.verificationID,
      "verified": this.verified,
      "emailed_at": this.emailedAt,
    };
  }

}
