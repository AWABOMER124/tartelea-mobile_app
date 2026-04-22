import 'package:flutter/widgets.dart';

class AppRadius {
  static const double xs = 12;
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius circular(double value) => BorderRadius.circular(value);

  static const BorderRadius card = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius panel = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius control = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(pill));
}

