class SakaLog {
  static String tag;

  static void init(String s) {
    tag = s;
  }

  static void log(String message) {
    if (tag == null) {
      tag = "saka_image";
    }
    print("$tag: ${DateTime.now().toString()}: $message");
  }
}
