class UserPrivateDetails {
  String userID;
  String firstName;
  String lastName;
  String fcmToken;
  String email;
  String studentEmail;
  String phoneNumber;

  UserPrivateDetails();

  factory UserPrivateDetails.fromJson(Map<String, dynamic> parsedJson) {
    return UserPrivateDetails()
      ..userID = parsedJson["userID"]
      ..firstName = parsedJson["firstName"]
      ..lastName = parsedJson["lastName"]
      ..fcmToken = parsedJson["fcmToken"]
      ..email = parsedJson["email"]
      ..studentEmail = parsedJson["studentEmail"]
      ..phoneNumber = parsedJson["phoneNumber"];
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
    };
  }

}