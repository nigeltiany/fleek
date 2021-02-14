import 'dart:io';

import 'package:dating/services/file_encryption.dart';
import 'package:file/local.dart';
import 'package:file/memory.dart';
import 'package:http/http.dart' as http;

Future<EncryptionResult> encryptFileAtPath(String path) async {
  // showProgress(context, 'Securing image...', false);
  var result = await encryptFile(LocalFileSystem(), File(path));
  // Navigator.of(context).pop();
  return result;
}

Future<File> decryptFileHelper(MemoryFileSystem fs, String secret, File file, String fileName) async {
  return await decryptFile(fs, FileSecret.fromString(secret), file, fileName);
}

Future<File> getFile(MemoryFileSystem fs, String url) async {
  var name = Uri.parse(url).queryParameters["token"];
  if (await fs.file(name).exists()) {
    return Future.value(fs.file(name));
  }
  var response = await http.get(url);
  var bytes = response.bodyBytes;
  return await fs.file(name).writeAsBytes(bytes); // Caller can do whatever it needs with these bytes without rereading the file
}