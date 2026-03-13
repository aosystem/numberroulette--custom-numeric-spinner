import 'package:flutter/animation.dart';

class ThreePhaseRouletteCurve extends Curve {
  final double easeInDuration;
  final double linearDuration;
  final double easeOutDuration;

  const ThreePhaseRouletteCurve({
    required this.easeInDuration,
    required this.linearDuration,
    required this.easeOutDuration,
  });

  @override
  double transformInternal(double t) {
    final total = easeInDuration + linearDuration + easeOutDuration;
    final easeInFrac = easeInDuration / total;
    final linearFrac = linearDuration / total;

    final distEaseIn = 0.5 * easeInDuration;
    final distLinear = 1.0 * linearDuration;
    final distEaseOut = 0.5 * easeOutDuration;
    final totalDist = distEaseIn + distLinear + distEaseOut;

    if (t < easeInFrac) {
      final time = t * total;
      final distance = 0.5 * time * time / easeInDuration;
      return distance / totalDist;
    } else if (t < easeInFrac + linearFrac) {
      final time = (t - easeInFrac) * total;
      final distance = distEaseIn + time;
      return distance / totalDist;
    } else {
      final time = (t - easeInFrac - linearFrac) * total;
      final v0 = 1.0;
      final a = -v0 / easeOutDuration;
      final distance = distEaseIn + distLinear + (v0 * time + 0.5 * a * time * time);
      return distance / totalDist;
    }
  }
}
