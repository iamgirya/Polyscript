import 'dart:io';

import 'package:flutter/services.dart';

class InputManager {
  static var isCtrlPressed = false;

  static bool isCharInputEvent(KeyEvent event) =>
      event.character != null &&
      event.logicalKey != LogicalKeyboardKey.enter &&
      event.logicalKey != LogicalKeyboardKey.backspace &&
      event.logicalKey != LogicalKeyboardKey.control;

  static bool isCtrlCEvent(KeyEvent event) => isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyC;

  static bool isCtrlVEvent(KeyEvent event) => isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyV;

  static bool isDeleteEvent(KeyEvent event) => event.logicalKey == LogicalKeyboardKey.backspace;

  static bool isNewLineEvent(KeyEvent event) => event.logicalKey == LogicalKeyboardKey.enter;

  static bool isControlPressed(KeyEvent event) => Platform.isWindows
      ? event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight
      : event.logicalKey == LogicalKeyboardKey.metaLeft || event.logicalKey == LogicalKeyboardKey.metaLeft;
}
