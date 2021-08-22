import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FramePainter extends CustomPainter{
  final List<Offset> _points;
  final _rectPaint = Paint()
    ..color = Colors.blue
    ..strokeWidth = 5;
  static const pointMode = PointMode.polygon;

  FramePainter(this._points);

  @override
  void paint(Canvas canvas, Size size) {
    // 記憶している点を描画する
    if (_points.length > 1) {
      var _tmpPoints = [..._points];
      _tmpPoints.add(_points.first);
      canvas.drawPoints(pointMode, _tmpPoints, _rectPaint);
    }
    else if(_points.length == 1) {
      canvas.drawRect(Rect.fromCenter(center: _points.first, width: 20.0, height: 20.0), _rectPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// 一番近い点のインデックスを取得
int getNearestPointIndex(List<Offset> points, Offset point) {
  List<double> distances = [];
  for (var offset in points) {
    distances.add((offset - point).distanceSquared);
  }
  return distances.indexOf(distances.reduce((min)));
}