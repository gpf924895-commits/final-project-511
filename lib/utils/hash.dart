import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Hash a string using SHA-256 and return hex string
String sha256Hex(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}





