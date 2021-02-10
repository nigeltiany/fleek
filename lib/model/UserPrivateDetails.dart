class UserPrivateDetails {
  String userID;
  String userName;
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
      ..userName = parsedJson["userName"]
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
      "userName": this.userName,
      "firstName": this.firstName,
      "lastName": this.lastName,
      "fcmToken": this.fcmToken,
      "email": this.email,
      "studentEmail": this.studentEmail,
      "phoneNumber": this.phoneNumber,
    };
  }

}