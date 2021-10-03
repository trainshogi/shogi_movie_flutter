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