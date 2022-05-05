import 'package:shogi_movie_flutter/domain/board.dart';
import 'package:shogi_movie_flutter/domain/piece_list.dart';

import '../domain/piece.dart';

bool isInitialPosition(String sfen){
  return sfen == Board().toSfen();
}

/// detect moved space.
///   pattern1: move piece
///   prevSpace > -1, nextSpace > -1
///   next: only recognize nextSpace
/// pattern2: put piece
///   prevSpace == -1, nextSpace > -1
///   next: only recognize nextSpace
/// pattern3: take piece
///   prevSpace > -1, nextSpace == -1
///   next: search all pieces and get diff
Map<String, int> getMovement(String prevPiecePlace, String nextPiecePlace) {
  var prevSpace = -1;
  var nextSpace = -1;
  for (int i = 0; i < prevPiecePlace.length; i++) {
    if (prevPiecePlace[i] != nextPiecePlace[i]) {
      if (nextPiecePlace[i] == "1") {
        prevSpace = i;
      }
      else {
        nextSpace = i;
      }
    }
  }
  return {"prevSpace": prevSpace, "nextSpace": nextSpace};
}

bool isSamePiece(Piece piece1, Piece piece2) {
  List<Piece> kings = [Piece.GYOKU, Piece.OU];
  List<Piece> vkings = [Piece.VGYOKU, Piece.VOU];
  if (kings.contains(piece1) && kings.contains(piece2)) {
    return true;
  }
  if (vkings.contains(piece1) && vkings.contains(piece2)) {
    return true;
  }
  return piece1 == piece2;
}

Map<String, int> getMovementWithBoard(Board prevBoard, Board nextBoard) {
  var prevSpace = -1;
  var nextSpace = -1;
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      if (!isSamePiece(prevBoard.board[i][j], nextBoard.board[i][j])) {
        if (nextBoard.board[i][j] == Piece.NONE) {
          prevSpace = i*10+j;
        }
        else {
          nextSpace = i*10+j;
        }
      }
    }
  }
  return {"prevSpace": prevSpace, "nextSpace": nextSpace};
}

String sfenMoveList2Sfen(List<String> sfenMoveList) {
  String header = "position startpos moves ";
  return header + sfenMoveList.join(" ");
}

String sfen2KentoLink(String sfen) {
  String urlHeader = 'https://www.kento-shogi.com/?moves=';
  String needlessHeader = "position startpos moves ";
  return urlHeader + sfen.replaceFirst(needlessHeader, "").replaceAll(" ", ".").replaceAll("+", "%2B").replaceAll("*", "%2A");
}

String intSpace2KifString(int space) {
  return (9 - space%10).toString() + (space~/10 + 1).toString();
}

String intSpace2SfenString(int space) {
  return (9 - space%10).toString() + String.fromCharCode(space~/10 + 1 + 96);
}

void updateBoard(int prevSpace, int nextSpace, Piece piece, Board board, bool nari) {
  // remove piece from prevSpace
  if (prevSpace != -1) {
    board.board[prevSpace~/10][prevSpace%10] = Piece.NONE;
  }
  else {
    if (firstPieceList.contains(piece)) {
      board.blackPiece[piece] = board.blackPiece[piece]! - 1;
      if (board.blackPiece[piece] == 0) { board.blackPiece.remove(piece); }
    }
    else {
      board.whitePiece[piece.original] = board.whitePiece[piece.original]! - 1;
      if (board.whitePiece[piece.original] == 0) { board.whitePiece.remove(piece.original); }
    }
  }

  // take piece from nextSpace
  Piece takePiece = board.board[nextSpace~/10][nextSpace%10].original;
  Piece takePieceUnPromoted = (takePiece.unpromoted != Piece.NONE) ? takePiece.unpromoted : takePiece;
  if (takePieceUnPromoted != Piece.NONE) {
    if (firstPieceList.contains(piece)) {
      board.blackPiece[takePieceUnPromoted] = (board.blackPiece[takePieceUnPromoted] ?? 0) + 1;
    }
    else {
      board.whitePiece[takePieceUnPromoted] = (board.whitePiece[takePieceUnPromoted] ?? 0) + 1;
    }
  }

  // put piece to nextSpace
  Piece nextPiece = (nari && piece.promoted != Piece.NONE) ? piece.promoted : piece;
  board.board[nextSpace~/10][nextSpace%10] = nextPiece;
}

String createKif(int prevSpace, int nextSpace, Piece piece, Board board, bool nari) {
  String placeStr = intSpace2KifString(nextSpace);
  String pieceStr = piece.original.japaneseOneChar;
  String putStr = (prevSpace == -1) ? "打" : "";
  String nariStr = nari ? "成" : "";
  return placeStr + pieceStr + putStr + nariStr;
}

String createSfenMove(int prevSpace, int nextSpace, Piece piece, Board prevBoard, bool nari) {
  String prevSpaceSfen = (prevSpace == -1) ? piece.sfen.toUpperCase() + "*" : intSpace2SfenString(prevSpace);
  String nextSpaceSfen = intSpace2SfenString(nextSpace);
  String nariStr = nari ? "+" : "";
  return prevSpaceSfen + nextSpaceSfen + nariStr;
}

List<String> createAudioFilenameList(int prevSpace, int nextSpace, Piece piece, Board board, String movePattern, bool nari) {
  List<String> filenameList = intSpace2KifString(nextSpace).split("");
  int head = firstNonPromotedPieceList.contains(piece.original) ? 10 : 9;
  filenameList.add((firstPieceList.indexOf(piece.original) + head).toString());
  if (movePattern == "put") {filenameList.add("32");}
  if (nari) {filenameList.add("30");}
  return filenameList;
}
