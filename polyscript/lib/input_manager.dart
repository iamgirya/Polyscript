import 'dart:io';

import 'package:flutter/services.dart';

extension InputEventManager on KeyEvent {
  static var isCtrlPressed = false;

  bool get isArrowRight => logicalKey == LogicalKeyboardKey.arrowRight;

  bool get isArrowLeft => logicalKey == LogicalKeyboardKey.arrowLeft;

  bool get isArrowUp => logicalKey == LogicalKeyboardKey.arrowUp;

  bool get isArrowDown => logicalKey == LogicalKeyboardKey.arrowDown;

  bool get isControl => Platform.isWindows
      ? logicalKey == LogicalKeyboardKey.controlLeft || logicalKey == LogicalKeyboardKey.controlRight
      : logicalKey == LogicalKeyboardKey.metaLeft || logicalKey == LogicalKeyboardKey.metaLeft;

  bool get isChar =>
      character != null &&
      logicalKey != LogicalKeyboardKey.enter &&
      logicalKey != LogicalKeyboardKey.backspace &&
      logicalKey != LogicalKeyboardKey.control;

  bool get isCtrlCEvent => isCtrlPressed && logicalKey == LogicalKeyboardKey.keyC;

  bool get isCtrlVEvent => isCtrlPressed && logicalKey == LogicalKeyboardKey.keyV;

  bool get isDeleteEvent => logicalKey == LogicalKeyboardKey.backspace;

  bool get isNewLineEvent => logicalKey == LogicalKeyboardKey.enter;
}
