import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:file/file.dart' show FileSystem;
import 'package:flutter/foundation.dart';
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

class _Work {
  final File file;
  final FileSecret fileSecret;
  _Work(this.file, this.fileSecret);
}

Future<Uint8List> _decrypt(_Work w) async {
  var fileBytes = await w.file.readAsBytes();
  return await _cipher.decrypt(
    fileBytes,
    secretKey: SecretKey(w.fileSecret.secret.codeUnits),
    nonce: Nonce(w.fileSecret.nonce.codeUnits),
  );
}

Future<File> decryptFile(MemoryFileSystem memoryFileSystem, FileSecret secret, File file, String fileName) async {
  final decrypted = await compute<_Work, Uint8List>(_decrypt, _Work(file, secret));
  return memoryFileSystem.file(fileName).writeAsBytes(decrypted);
}