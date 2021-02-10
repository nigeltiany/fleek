import 'package:dating/model/User.dart';
import 'package:flutter/foundation.dart';

class FleekData with ChangeNotifier {

  Stream<List<AppUser>> _users;

  Stream<List<AppUser>> get users => _users;

  set users(Stream<List<AppUser>> users) {
    _users = users;
    notifyListeners();
  }

}