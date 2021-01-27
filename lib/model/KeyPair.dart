import 'package:dating/model/ChatModel.dart';

class KeyPair {

  String privateKeyBase64;
  String publicKeyBase64;

  KeyPair({
    this.privateKeyBase64,
    this.publicKeyBase64
  });

  factory KeyPair.fromJson(Map<String, dynamic> parsedJson) {
    return KeyPair(
      privateKeyBase64: parsedJson["PrivateKey"],
      publicKeyBase64: parsedJson["PublicKey"],
    );
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

class EncrypterState {
  Encrypter encrypter;
  EncrypterState(this.encrypter);
}