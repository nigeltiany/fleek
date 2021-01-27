import 'User.dart';

class ContactModel {
  ContactType type = ContactType.UNKNOWN;
  AppUser user = AppUser();

  ContactModel({this.type, this.user});
}

enum ContactType { FRIEND, PENDING, BLOCKED, UNKNOWN, ACCEPT }
