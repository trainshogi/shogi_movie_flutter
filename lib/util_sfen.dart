String initial_sfen = "lnsgkgsnl/1r5b1/ppppppppp/9/9/9/PPPPPPPPP/1B5R1/LNSGKGSNL";

List<String> pieceNameListJapanese = [
    "歩兵", "香車", "桂馬", "銀将", "金将", "角行", "飛車", "王将",
    "と金", "成香", "成桂", "成銀", "竜馬", "龍王"
];

List<String> pieceNameListJapaneseOneChar = [
  "歩", "香", "桂", "銀", "金", "角", "飛", "王",
  "と", "杏", "圭", "全", "馬", "龍"
];
List<String> pieceNameListEnglish = [
//        "vfu"
  "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou",
  "vfu", "vkyo", "vkei", "vgin", "vkin", "vkaku", "vhisya", "vou"
//        "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou",
//        "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya"
];
List<String> pieceNameListSfen = [
//        "p"
    "P", "L", "N", "S", "G", "B", "R", "K", "p", "l", "n", "s", "g", "b", "r", "k"
//        "+P", "+L", "+N", "+S", "+B", "+R"
];

bool isInitialPosition(String sfen){
  return sfen == initial_sfen;
}

List<String> sfenSpacePurge(String sfen) {
  var sfenPurge = <String>[];
  sfen.split("").forEach((char) {
    final number = num.tryParse(char);
    if (number != null) {
      List<String> tmp = [for(var i=0; i<number; i+=1) " 1"];
      sfenPurge.addAll(tmp);
    }
    else {
      sfenPurge.add(" " + char);
    }
  });
  return sfenPurge;
}

String sfenPieceName2Filename(String pieceNameSfen) {
  return (pieceNameListSfen.indexOf(pieceNameSfen) + 10).toString();
}

String sfenPieceName2Japanese(String pieceNameSfen) {
  return pieceNameListJapaneseOneChar[pieceNameListSfen.indexOf(pieceNameSfen)];
}

List<String> sfenList2AudioFilename(List<String> sfenList) {
  var result = <String>[];
  sfenList.asMap().forEach((key, value) {
    if (key < 2) {
      // value is place, so no need to convert
      result.add(value);
    }
    else if (key == 2) {
      result.add(sfenPieceName2Filename(value));
    }
  });
  return result;
}

String sfenList2Kif(List<String> sfenList) {
  var result = "";
  sfenList.asMap().forEach((key, value) {
    if (key < 2) {
      // value is place, so no need to convert
      result += value;
    }
    else if (key == 2) {
      result += sfenPieceName2Japanese(value);
    }
  });
  return result;
}

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

String getSfenMovement(String prevSfen, String nextSfen) {
  var sfenMove = "";
  var prevSfenPurged = sfenSpacePurge(prevSfen);
  var nextSfenPurged = sfenSpacePurge(nextSfen);
  var prevSpace = [0, 0];
  var nextSpace = [0, 0];
  var prevPiece = "";
  var nextPiece = "";
  for (int i = 0; i < prevSfenPurged.length; i++) {
    if (prevSfenPurged[i] != nextSfenPurged[i]) {
      if (nextSfenPurged[i] == " 1") {
        prevSpace = [9 - i%10, i~/10 + 1];
        prevPiece = prevSfenPurged[i];
      }
      else {
        nextSpace = [9 - i%10, i~/10 + 1];
        nextPiece = nextSfenPurged[i];
      }
    }
  }

  if (prevPiece.isEmpty) {
    // put piece
    sfenMove += nextPiece[1].toUpperCase() + "*";
  }
  else {
    sfenMove += prevSpace[0].toString();
    sfenMove += String.fromCharCode(prevSpace[1] + 97);
  }
  sfenMove += nextSpace[0].toString();
  sfenMove += String.fromCharCode(nextSpace[1] + 97);
  if (prevPiece[0] == " " && nextPiece[0] == "+") {
    // promote piece
    sfenMove += "+";
  }

  return sfenMove;
}

List<String> getKifMovement(String prevSfen, String nextSfen) {
  var prevSfenPurged = sfenSpacePurge(prevSfen);
  var nextSfenPurged = sfenSpacePurge(nextSfen);
  var prevSpace = [0, 0];
  var nextSpace = [0, 0];
  var prevPiece = "";
  var nextPiece = "";
  for (int i = 0; i < prevSfenPurged.length; i++) {
    if (prevSfenPurged[i] != nextSfenPurged[i]) {
      if (nextSfenPurged[i] == " 1") {
        prevSpace = [9 - i%10, i~/10 + 1];
        prevPiece = prevSfenPurged[i];
      }
      else {
        nextSpace = [9 - i%10, i~/10 + 1];
        nextPiece = nextSfenPurged[i];
      }
    }
  }
  if (prevPiece.isEmpty) {
    // put piece
    return [];
  }
  else if (prevPiece[0] == " " && nextPiece[0] == "+") {
    // promote piece
  }
  else {
    // move piece
    return [nextSpace[0].toString(), nextSpace[1].toString(), nextPiece[1].toString()];
  }
  return [];
}

String sfenMoveList2Sfen(List<String> sfenMoveList) {
  String header = "position startpos moves ";
  return header + sfenMoveList.join(" ");
}

String sfen2KentoLink(String sfen) {
  String URLHeader = 'https://www.kento-shogi.com/?moves=';
  String needlessHeader = "position startpos moves ";
  return URLHeader + sfen.replaceFirst(needlessHeader, "").replaceAll(" ", ".").replaceAll("+", "%2B").replaceAll("*", "%2A");
}

String intSpace2KifString(int space) {
  return (9 - space%10).toString() + (space~/10 + 1).toString();
}

String intSpace2SfenString(int space) {
  return (9 - space%10).toString() + String.fromCharCode(space~/10 + 1 + 96);
}

String createKif(int prevSpace, int nextSpace, String pieceNameEnglish, String prevSfen) {
  String place = intSpace2KifString(nextSpace);
  String piece = pieceNameListJapanese[pieceNameListEnglish.indexOf(pieceNameEnglish)];
  return place + piece;
  // if (prevPiece.isEmpty) {
  //   // put piece
  //   return baseKif + "打";
  // }
  // else if (prevPiece[0] == " " && nextPiece[0] == "+") {
  //   // promote piece
  // }
  // else {
  //   // move piece
  //   return ;
  // }
  // return [];
}

String createSfenMove(int prevSpace, int nextSpace, String pieceNameEnglish, String prevSfen) {
  String prevSpaceSfen = intSpace2SfenString(prevSpace);
  String nextSpaceSfen = intSpace2SfenString(nextSpace);
  return prevSpaceSfen + nextSpaceSfen;
  // if (prevPiece.isEmpty) {
  //   // put piece
  //   return baseKif + "打";
  // }
  // else if (prevPiece[0] == " " && nextPiece[0] == "+") {
  //   // promote piece
  // }
  // else {
  //   // move piece
  //   return ;
  // }
  // return [];
}

String createSfenPhase() {
  return "";
}

List<String> createAudioFilenameList() {
  return [""];
}