import 'package:shogi_movie_flutter/domain/piece.dart';
import 'package:shogi_movie_flutter/domain/piece_list.dart';

class Board{
  Map<Piece, int> blackPiece = {};
  Map<Piece, int> whitePiece = {};
  List<List<Piece>> board = [
    [Piece.VKYO, Piece.VKEI, Piece.VGIN, Piece.VKIN, Piece.VOU, Piece.VKIN, Piece.VGIN, Piece.VKEI, Piece.VKYO],
    [Piece.NONE, Piece.VHISYA, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.VKAKU, Piece.NONE],
    [Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU, Piece.VFU],
    [Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE],
    [Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE],
    [Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE],
    [Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU, Piece.FU],
    [Piece.NONE, Piece.KAKU, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.NONE, Piece.HISYA, Piece.NONE],
    [Piece.KYO, Piece.KEI, Piece.GIN, Piece.KIN, Piece.GYOKU, Piece.KIN, Piece.GIN, Piece.KEI, Piece.KYO]
  ];
  
  void clearBoard() {
    board = List.generate(9, (_) => List.generate(9, (_) => Piece.NONE));
  }

  Board();

  Board.init(this.blackPiece, this.whitePiece, this.board);

  Board fromSfen(String sfen) {
    Map<Piece, int> blackPiece = {};
    Map<Piece, int> whitePiece = {};
    List<List<Piece>> board = List.generate(9, (_) => List.generate(9, (_) => Piece.NONE));
    int index = 0;
    bool promote = false;
    String sfenBoard = sfen.split(" ")[0];
    for (String char in sfenBoard.split("")) {
      if (char == "/") {
        promote = false;
        index += 1;
      }
      else if (char == "+") {
        promote = true;
      }
      else if (int.tryParse(char) == null) {
        Piece piece = Piece.values.firstWhere((element) => element.sfen == char);
        board[index~/10][index%10] = promote ? piece.promoted : piece;
        promote = false;
        index += 1;
      }
      else {
        for (int i = 1; i <= int.parse(char); i++) {
          board[index~/10][index%10] = Piece.NONE;
          promote = false;
          index += 1;
        }
      }
    }

    if (sfen.split(" ").length > 1) {
      // ignore turn (w or b)

      // blackPiece and whitePiece
      int num = 1;
      String pieces = sfen.split(" ")[2];
      for (String char in pieces.split("")) {
        if (int.tryParse(char) == null) {
          Piece piece = Piece.values.firstWhere((element) => element.sfen == char);
          firstPieceList.contains(piece) ? blackPiece[piece] = num : whitePiece[piece] = num;
          num = 1;
        }
        else {
          num = int.parse(char);
        }
      }

      // ignore tesuu and kifu
    }

    return Board.init(blackPiece, whitePiece, board);
  }

  String toSfen() {
    List<String> sfenArray = [];
    for (List<Piece> line in board) {
      int spaceNumber = 0;
      String mergedSfen = "";
      for (Piece place in line) {
        if (place != Piece.NONE) {
          if (spaceNumber > 0) {
            mergedSfen += spaceNumber.toString();
            spaceNumber = 0;
          }
          mergedSfen += place.sfen;
        }
        else {
          spaceNumber += 1;
        }
      }
      if (spaceNumber > 0) {
        mergedSfen += spaceNumber.toString();
      }
      sfenArray.add(mergedSfen);
    }
    String boardStr = sfenArray.join("/");
    if (blackPiece.isEmpty && whitePiece.isEmpty) return boardStr;
    String turn = "b";
    String pieces = "";
    blackPiece.forEach((key, value) {
      value == 1 ? pieces += key.sfen : pieces += value.toString() + key.sfen;
    });
    whitePiece.forEach((key, value) {
      value == 1 ? pieces += key.sfen : pieces += value.toString() + key.sfen;
    });
    String tesuu = "1";
    return boardStr + " " + turn + " " + pieces + " " + tesuu;
  }

  String toKif() {
    List<String> sfenArray = [];
    for (List<Piece> line in board) {
      int spaceNumber = 0;
      String mergedSfen = "";
      for (Piece place in line) {
        if (place != Piece.NONE) {
          if (spaceNumber > 0) {
            mergedSfen += spaceNumber.toString();
            spaceNumber = 0;
          }
          mergedSfen += place.sfen;
        }
        else {
          spaceNumber += 1;
        }
      }
      if (spaceNumber > 0) {
        mergedSfen += spaceNumber.toString();
      }
      sfenArray.add(mergedSfen);
    }
    String boardStr = sfenArray.join("/");
    if (blackPiece.isEmpty && whitePiece.isEmpty) return boardStr;
    String turn = "b";
    String pieces = "";
    blackPiece.forEach((key, value) {
      value == 1 ? pieces += key.sfen : pieces += value.toString() + key.sfen;
    });
    whitePiece.forEach((key, value) {
      value == 1 ? pieces += key.sfen : pieces += value.toString() + key.sfen;
    });
    String tesuu = "1";
    return boardStr + " " + turn + " " + pieces + " " + tesuu;
  }
}