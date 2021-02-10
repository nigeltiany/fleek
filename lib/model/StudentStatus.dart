import 'package:cloud_firestore/cloud_firestore.dart' as Firestore;

class StudentStatus {

  String userID = "";
  String verificationID ="";
  bool verified = false;
  String studentEmail;
  Firestore.Timestamp emailedAt = Firestore.Timestamp.now();

  StudentStatus({
    this.userID,
    this.verificationID,
    this.verified,
    this.emailedAt,
    this.studentEmail,
  });

  factory StudentStatus.fromJson(Map<String, dynamic> parsedJson) {
    return StudentStatus(
      userID: parsedJson["user_id"] ?? "",
      verificationID: parsedJson["verification_id"] ?? "",
      verified: parsedJson["verified"] ?? false,
      emailedAt: parsedJson["emailed_at"],
      studentEmail: parsedJson["student_email"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": this.userID,
      "verification_id": this.verificationID,
      "verified": this.verified,
      "emailed_at": this.emailedAt,
      "student_email": this.studentEmail,
    };
  }

}
