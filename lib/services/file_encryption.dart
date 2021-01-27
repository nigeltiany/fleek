import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';
import 'package:file/file.dart' show FileSystem;
import 'package:flutter/material.dart';
import 'package:path/path.dart' show basename;
import 'package:path_provider/path_provider.dart';
import 'package:file/memory.dart';

const _cipher = aesGcm;

class FileSecret {

  final String secret;
  final String nonce;

  FileSecret({
    @required this.secret,
    @required this.nonce
  });

  @override
  String toString() {
    return json.encode({
      "secret": this.secret,
      "nonce": this.nonce
    });
  }

  static fromString(String source) {
    var fileSecret = json.decode(source);
    return FileSecret(secret: fileSecret["secret"], nonce: fileSecret["nonce"]);
  }

}

class EncryptionResult {

  final FileSecret fileSecret;
  final File file;

  EncryptionResult(this.fileSecret, this.file);

  @override
  String toString() {
    return fileSecret.toString();
  }

}

Future<EncryptionResult> encryptFile (FileSystem fs, File file) async {

  final secretKey = await _cipher.newSecretKey();
  final secret = await secretKey.extract();
  final nonce = _cipher.newNonce();

  var plainText = await file.readAsBytes();
  final encrypted = await _cipher.encrypt(
    plainText,
    secretKey: secretKey,
    nonce: nonce,
  );

  String dir = (await getTemporaryDirectory()).path;
  File encryptedFile = await fs.file('$dir/${basename(file.path)}').writeAsBytes(encrypted);

  return EncryptionResult(
    FileSecret(
      secret: String.fromCharCodes(secret),
      nonce: String.fromCharCodes(nonce.bytes),
    ),
    encryptedFile,
  );

}

Future<File> decryptFile(MemoryFileSystem memoryFileSystem, FileSecret secret, File file, String fileName) async {

  var fileBytes = await file.readAsBytes();
  final decrypted = await _cipher.decrypt(
    fileBytes,
    secretKey: SecretKey(secret.secret.codeUnits),
    nonce: Nonce(secret.nonce.codeUnits),
  );

  return memoryFileSystem.file(fileName).writeAsBytes(decrypted);

}