class StudentStatus {

  String userID = "";
  String verificationID ="";
  bool verified = false;

  StudentStatus({
    this.userID,
    this.verificationID,
    this.verified,
  });

  factory StudentStatus.fromJson(Map<String, dynamic> parsedJson) {
    return StudentStatus(
      userID: parsedJson["user_id"] ?? "",
      verificationID: parsedJson["verification_id"] ?? "",
      verified: parsedJson["verified"] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "user_id": this.userID,
      "verification_id": this.verificationID,
      "verified": this.verified
    };
  }

}
