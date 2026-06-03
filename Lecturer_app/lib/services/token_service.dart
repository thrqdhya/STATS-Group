import 'dart:convert';

import 'package:crypto/crypto.dart';

class TokenService {

  static const String secretKey =
      "super_secret_key";

  static const int interval = 30;

  String generateToken() {

    final now = DateTime.now();

    final timeString =
        "${now.year}"
        "${now.month.toString().padLeft(2, '0')}"
        "${now.day.toString().padLeft(2, '0')}"
        "-"
        "${now.hour.toString().padLeft(2, '0')}"
        "${now.minute.toString().padLeft(2, '0')}"
        "${now.second.toString().padLeft(2, '0')}";

    final currentInterval =
        DateTime.now()
            .millisecondsSinceEpoch ~/
        1000 ~/
        interval;

    final raw =
        "$currentInterval$secretKey";

    final hash =
        sha256
            .convert(
              utf8.encode(raw),
            )
            .toString()
            .substring(0, 8);

    return "ATTEND-$timeString-$hash";
  }
}