
import 'dart:ui';

List<Offset> absolutePoints2relativePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var relativePoints = <Offset>[];
  points.forEach((Offset point) {
    relativePoints.add(Offset(100 * point.dx / size.width, 100 * point.dy / size.height));
  });
  return relativePoints;
}

List<Offset> relativePoints2absolutePoints(List<Offset> points, Size size) {
  // get PainterSize
  print("ウィジェットのサイズ: $size");
  // convert to relative
  var absolutePoints = <Offset>[];
  points.forEach((Offset point) {
    absolutePoints.add(Offset(size.width * (point.dx / 100), size.height * (point.dy / 100)));
  });
  return absolutePoints;
}

List<Offset> string2Offsets(String row) {
  var offsets = <Offset>[];
  List<String> rowOffsets = row.split(':');
  for (var rowOffset in rowOffsets) {
    var formatted = rowOffset
        .replaceAll(" ", "")
        .replaceFirst("Offset(", "")
        .replaceFirst(")", "")
        .split(",");
    offsets.add(Offset(double.parse(formatted[0]), double.parse(formatted[1])));
  }
  return offsets;
}