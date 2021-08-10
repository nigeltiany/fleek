class UserPrivateDetails {
  String userID;
  String firstName;
  String lastName;
  String fcmToken;
  String email;
  String studentEmail;
  String phoneNumber;
  bool verified = true;

  UserPrivateDetails({
    this.userID,
    this.firstName,
    this.lastName,
    this.fcmToken,
    this.email,
    this.studentEmail,
    this.phoneNumber,
    this.verified,
  });

  factory UserPrivateDetails.fromJson(Map<String, dynamic> parsedJson) {
    return UserPrivateDetails()
      ..userID = parsedJson["userID"]
      ..firstName = parsedJson["firstName"]
      ..lastName = parsedJson["lastName"]
      ..fcmToken = parsedJson["fcmToken"]
      ..email = parsedJson["email"]
      ..studentEmail = parsedJson["studentEmail"]
      ..phoneNumber = parsedJson["phoneNumber"]
      ..verified = parsedJson["verified"] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      "userID": this.userID,
      "firstName": this.firstName,
      "lastName": this.lastName,
      "fcmToken": this.fcmToken,
      "email": this.email,
      "studentEmail": this.studentEmail,
      "phoneNumber": this.phoneNumber,
      "verified": this.verified,
    };
  }

}