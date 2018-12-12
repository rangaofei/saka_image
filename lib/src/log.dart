import 'package:flutter/foundation.dart';

class SakaLog {
  static String tag = 'saka_image';

  static void init({String s, int level}) {
    tag = s;
  }

  static void log(String message) {
    debugPrint("${DateTime.now().toString()}: $tag: $message");
  }
}
