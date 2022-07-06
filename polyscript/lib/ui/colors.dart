import 'dart:math';

import 'package:flutter/material.dart';

const background = Color(0xFFFFFFFF);
const highlight = Color(0xFFF4F4F4);
const divider = Color(0xFFE1E1E1);
const disable = Color(0xFFB6B6B6);
const text = Color(0xFF000000);

Color randomCursorColor() {
  switch (Random().nextInt(6)) {
    case 0:
      return Colors.indigo;
    case 1:
      return Colors.blue;
    case 2:
      return Colors.pink;
    case 3:
      return Colors.green;
    case 4:
      return Colors.brown;
    case 5:
      return Colors.teal;
  }

  return Colors.black;
}
