import 'dart:ui';

class Contour {
  List<Offset> absolute = [];
  List<Offset> relative = [];

  Contour(this.absolute, this.relative);

  Contour.fromJson(Map<String, dynamic> json) {
    List<List<double>> absoluteList = json["absolute"];
    for (var element in absoluteList) {absolute.add(Offset(element[0], element[1]));}
    List<List<double>> relativeList = json["relative"];
    for (var element in relativeList) {relative.add(Offset(element[0], element[1]));}
  }

  dynamic toJson() {
    List<List<double>> absoluteList = [];
    for (var element in absolute) {absoluteList.add([element.dx, element.dy]);}
    List<List<double>> relativeList = [];
    for (var element in relative) {relativeList.add([element.dx, element.dy]);}
    return {"absolute": absoluteList, "relative": relativeList};
  }
}