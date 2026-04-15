import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class PlatformUtils {
  static bool get isTV {
    if (!kIsWeb && Platform.isAndroid) {
      // Android TV detection: screen width >= 960dp typically
      return true; // fallback — use BuildContext version below
    }
    return false;
  }

  static bool isTVScreen(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shorter = size.shortestSide;
    // TVs have large screen sizes AND no touch input typically
    return shorter >= 600 && _hasNoTouch(context);
  }

  static bool _hasNoTouch(BuildContext context) {
    return MediaQuery.of(context).navigationMode == NavigationMode.directional;
  }
}
