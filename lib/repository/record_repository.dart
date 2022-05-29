
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';

import '../controller/file_controller.dart';
import '../domain/board.dart';

class RecordRepository {
  static const platformPieceDetect = MethodChannel('com.nkkuma.dev/piece_detect');
  String directoryPath = "";

  RecordRepository(String dirName) {
    FileController.directoryPath(dirName).then((value) => directoryPath = value);
  }

  // call invokeMethod
  Future<dynamic> callInvokeMethod(Map<String, dynamic> map) {
    var platform = map['platform'] as MethodChannel;
    var methodName = map['methodName'];
    var args = map['args'];
    return platform.invokeMethod(methodName, args);
  }

  Future<Map<String, dynamic>> getPiecePlace(
      String imageFilePath,
      List<Offset> relativePoints) {
    return callInvokeMethod({
      "platform": platformPieceDetect,
      "methodName": "piece_place_detect",
      "args": {
        'srcPath': imageFilePath,
        'dirName': directoryPath,
        'points': relativePoints.toString()
      }
    }).then((value) => jsonDecode(value as String));
  }

  Future<Map<String, dynamic>> onePieceDetect(
      String imageFilePath,
      List<Offset> relativePoints,
      Map<String, int> moveMap,
      String pieceNames) {
    return callInvokeMethod({
      "platform": platformPieceDetect,
      "methodName": "one_piece_detect",
      "args": {
        'srcPath': imageFilePath,
        'dirName': directoryPath,
        'points': relativePoints.toString(),
        'space': (moveMap["nextSpace"]!%10).toString() + "," + (moveMap["nextSpace"]!/10).floor().toString(),
        'pieceNames': pieceNames
      }
    }).then((value) => jsonDecode(value as String));
  }

  Future<Map<String, dynamic>> allPieceDetect(
      String imageFilePath,
      List<Offset> relativePoints,
      Board board,
      String pieceNames) {
    return callInvokeMethod({
      "platform": platformPieceDetect,
      "methodName": "all_piece_detect",
      "args": {
        'srcPath': imageFilePath,
        'dirName': directoryPath,
        'points': relativePoints.toString(),
        'sfen': board.toSfen(),
        'pieceNames': pieceNames
      }
    }).then((value) => jsonDecode(value as String));
  }
}