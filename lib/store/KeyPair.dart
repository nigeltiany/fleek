import 'package:flutter/cupertino.dart';

typedef Encrypter = Future<String> Function(String message);

class KeyPair with ChangeNotifier {

  String _privateKeyBase64;

  String get privateKeyBase64 => _privateKeyBase64;

  set privateKeyBase64(String privateKeyBase64) {
    notifyListeners();
    _privateKeyBase64 = privateKeyBase64;
  }

  String _publicKeyBase64;

  String get publicKeyBase64 => _publicKeyBase64;

  set publicKeyBase64(String publicKeyBase64) {
    notifyListeners();
    _publicKeyBase64 = publicKeyBase64;
  }

  KeyPair();

  factory KeyPair.fromJson(Map<String, dynamic> parsedJson) {
    var key =  KeyPair();
    key.privateKeyBase64 = parsedJson["PrivateKey"];
    key.publicKeyBase64 = parsedJson["PublicKey"];
    return key;
  }

  Map<String, dynamic> toJson() {
    return {
      "public_key": this.publicKeyBase64, // only base64 public key can be exposed
      "private_key": "<omitted>"
    };
  }

}

class KeyException implements Exception {

  final dynamic message;

  KeyException([this.message]);

  String toString() {
    Object message = this.message;
    if (message == null) return "KeyException";
    return "KeyException: $message";
  }

}

class EncrypterState with ChangeNotifier {

  Encrypter _encrypter;

  Encrypter get encrypter => _encrypter;

  set encrypter(Encrypter encrypter) {
    notifyListeners();
    _encrypter = encrypter;
  }

  EncrypterState(this._encrypter);

}