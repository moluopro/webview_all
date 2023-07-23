import 'dart:io';
import 'package:flutter/foundation.dart';

bool isMobile() {
  if (isAndroid()) {
    return true;
  }
  if (isIOS()) {
    return true;
  }
  return false;
}

bool isWeb() {
  return kIsWeb == true;
}

bool isDesktop() {
  if (isWindows()) {
    return true;
  }
  if (isMacOS()) {
    return true;
  }
  if (isLinux()) {
    return true;
  }
  return false;
}

bool isAndroid() {
  return isWeb() ? false : Platform.isAndroid;
}

bool isIOS() {
  return isWeb() ? false : Platform.isIOS;
}

isWindows() {
  return isWeb() ? false : Platform.isWindows;
}

isMacOS() {
  return isWeb() ? false : Platform.isMacOS;
}

isLinux() {
  return isWeb() ? false : Platform.isLinux;
}
