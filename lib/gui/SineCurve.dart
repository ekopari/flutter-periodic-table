import 'dart:math';

import 'package:flutter/material.dart';

class SineCurve extends Curve {
  const SineCurve() : super();

  @override
  double transformInternal(double t) {
    // t from 0 to 1, sin from 0 to pi/2
    t *= pi / 2;
    return sin(t);
  }

  double tWhereValueIs(double v) {
    double t = asin(v) / (pi / 2);
    return t;
  }
}

class DelayedSineCurve extends Curve {
  final double delay;
  late final double sinAtDelay;
  DelayedSineCurve({required this.delay}) {
    sinAtDelay = sin(delay * pi / 2);
  }

  @override
  double transformInternal(double t) {
    if (t < delay) {
      return 0;
    } else {
      t *= pi / 2;
      double sint = sin(t);
      double maxdiff = 1 - sinAtDelay;
      return (sint - sinAtDelay) * (1 / maxdiff);
    }
  }
}
