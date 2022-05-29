import 'dart:ui';

import 'board.dart';

class BoardState{
  Board board = Board();
  List<Offset> relativePoints = [];
  String currentPiecePlace = "ZZZZZZZZZ/1Z11111Z1/ZZZZZZZZZ/111111111/111111111/111111111/ZZZZZZZZZ/1Z11111Z1/ZZZZZZZZZ";
  String currentKif = "";
  List<String> sfenMoveList = [];
  int currentMoveNumber = 0;
}