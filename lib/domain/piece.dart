enum Piece {
  NONE,
  EMPTY,
  EXIST,
  FU,
  KYO,
  KEI,
  GIN,
  KIN,
  KAKU,
  HISYA,
  OU,
  GYOKU,
  NFU,
  NKYO,
  NKEI,
  NGIN,
  NKAKU,
  NHISYA,
  VFU,
  VKYO,
  VKEI,
  VGIN,
  VKIN,
  VKAKU,
  VHISYA,
  VOU,
  VGYOKU,
  VNFU,
  VNKYO,
  VNKEI,
  VNGIN,
  VNKAKU,
  VNHISYA
}

extension PieceExtension on Piece {
  String get japanese {
    switch (this) {
      case Piece.NONE:
        return "";
      case Piece.EMPTY:
        return "";
      case Piece.EXIST:
        return "";
      case Piece.FU:
        return "歩兵";
      case Piece.KYO:
        return "香車";
      case Piece.KEI:
        return "桂馬";
      case Piece.GIN:
        return "銀将";
      case Piece.KIN:
        return "金将";
      case Piece.KAKU:
        return "角行";
      case Piece.HISYA:
        return "飛車";
      case Piece.OU:
        return "王将";
      case Piece.GYOKU:
        return "玉将";
      case Piece.NFU:
        return "と金";
      case Piece.NKYO:
        return "成香";
      case Piece.NKEI:
        return "成桂";
      case Piece.NGIN:
        return "成銀";
      case Piece.NKAKU:
        return "竜馬";
      case Piece.NHISYA:
        return "龍王";
      case Piece.VFU:
        return "v歩兵";
      case Piece.VKYO:
        return "v香車";
      case Piece.VKEI:
        return "v桂馬";
      case Piece.VGIN:
        return "v銀将";
      case Piece.VKIN:
        return "v金将";
      case Piece.VKAKU:
        return "v角行";
      case Piece.VHISYA:
        return "v飛車";
      case Piece.VOU:
        return "v王将";
      case Piece.VGYOKU:
        return "v玉将";
      case Piece.VNFU:
        return "vと金";
      case Piece.VNKYO:
        return "v成香";
      case Piece.VNKEI:
        return "v成桂";
      case Piece.VNGIN:
        return "v成銀";
      case Piece.VNKAKU:
        return "v竜馬";
      case Piece.VNHISYA:
        return "v龍王";
    }
  }
  String get japaneseOneChar {
    switch (this) {
      case Piece.NONE:
        return "";
      case Piece.EMPTY:
        return "";
      case Piece.EXIST:
        return "";
      case Piece.FU:
        return "歩";
      case Piece.KYO:
        return "香";
      case Piece.KEI:
        return "桂";
      case Piece.GIN:
        return "銀";
      case Piece.KIN:
        return "金";
      case Piece.KAKU:
        return "角";
      case Piece.HISYA:
        return "飛";
      case Piece.OU:
        return "王";
      case Piece.GYOKU:
        return "玉";
      case Piece.NFU:
        return "と";
      case Piece.NKYO:
        return "杏";
      case Piece.NKEI:
        return "圭";
      case Piece.NGIN:
        return "全";
      case Piece.NKAKU:
        return "馬";
      case Piece.NHISYA:
        return "龍";
      case Piece.VFU:
        return "v歩";
      case Piece.VKYO:
        return "v香";
      case Piece.VKEI:
        return "v桂";
      case Piece.VGIN:
        return "v銀";
      case Piece.VKIN:
        return "v金";
      case Piece.VKAKU:
        return "v角";
      case Piece.VHISYA:
        return "v飛";
      case Piece.VOU:
        return "v王";
      case Piece.VGYOKU:
        return "v玉";
      case Piece.VNFU:
        return "vと";
      case Piece.VNKYO:
        return "v杏";
      case Piece.VNKEI:
        return "v圭";
      case Piece.VNGIN:
        return "v全";
      case Piece.VNKAKU:
        return "v馬";
      case Piece.VNHISYA:
        return "v龍";
    }
  }
  String get english {
    switch (this) {
      case Piece.NONE:
        return "";
      case Piece.EMPTY:
        return "";
      case Piece.EXIST:
        return "";
      case Piece.FU:
        return "fu";
      case Piece.KYO:
        return "kyo";
      case Piece.KEI:
        return "kei";
      case Piece.GIN:
        return "gin";
      case Piece.KIN:
        return "kin";
      case Piece.KAKU:
        return "kaku";
      case Piece.HISYA:
        return "hisya";
      case Piece.OU:
        return "ou";
      case Piece.GYOKU:
        return "gyoku";
      case Piece.NFU:
        return "nfu";
      case Piece.NKYO:
        return "nkyo";
      case Piece.NKEI:
        return "nkei";
      case Piece.NGIN:
        return "ngin";
      case Piece.NKAKU:
        return "nkaku";
      case Piece.NHISYA:
        return "nhisya";
      case Piece.VFU:
        return "vfu";
      case Piece.VKYO:
        return "vkyo";
      case Piece.VKEI:
        return "vkei";
      case Piece.VGIN:
        return "vgin";
      case Piece.VKIN:
        return "vkin";
      case Piece.VKAKU:
        return "vkaku";
      case Piece.VHISYA:
        return "vhisya";
      case Piece.VOU:
        return "vou";
      case Piece.VGYOKU:
        return "vgyoku";
      case Piece.VNFU:
        return "vnfu";
      case Piece.VNKYO:
        return "vnkyo";
      case Piece.VNKEI:
        return "vnkei";
      case Piece.VNGIN:
        return "vngin";
      case Piece.VNKAKU:
        return "vnkaku";
      case Piece.VNHISYA:
        return "vnhisya";
    }
  }
  String get sfen {
    switch (this) {
      case Piece.NONE:
        return "";
      case Piece.EMPTY:
        return "1";
      case Piece.EXIST:
        return "Z";
      case Piece.FU:
        return "P";
      case Piece.KYO:
        return "L";
      case Piece.KEI:
        return "N";
      case Piece.GIN:
        return "S";
      case Piece.KIN:
        return "G";
      case Piece.KAKU:
        return "B";
      case Piece.HISYA:
        return "R";
      case Piece.OU:
        return "K";
      case Piece.GYOKU:
        return "K";
      case Piece.NFU:
        return "+P";
      case Piece.NKYO:
        return "+L";
      case Piece.NKEI:
        return "+N";
      case Piece.NGIN:
        return "+S";
      case Piece.NKAKU:
        return "+B";
      case Piece.NHISYA:
        return "+R";
      case Piece.VFU:
        return "p";
      case Piece.VKYO:
        return "l";
      case Piece.VKEI:
        return "n";
      case Piece.VGIN:
        return "s";
      case Piece.VKIN:
        return "g";
      case Piece.VKAKU:
        return "b";
      case Piece.VHISYA:
        return "r";
      case Piece.VOU:
        return "k";
      case Piece.VGYOKU:
        return "k";
      case Piece.VNFU:
        return "+p";
      case Piece.VNKYO:
        return "+l";
      case Piece.VNKEI:
        return "+n";
      case Piece.VNGIN:
        return "+s";
      case Piece.VNKAKU:
        return "+b";
      case Piece.VNHISYA:
        return "+r";
    }
  }
  Piece get promoted {
    switch (this) {
      case Piece.FU:
        return Piece.NFU;
      case Piece.KYO:
        return Piece.NKYO;
      case Piece.KEI:
        return Piece.NKEI;
      case Piece.GIN:
        return Piece.NGIN;
      case Piece.KAKU:
        return Piece.NKAKU;
      case Piece.HISYA:
        return Piece.NHISYA;
      case Piece.VFU:
        return Piece.VNFU;
      case Piece.VKYO:
        return Piece.VNKYO;
      case Piece.VKEI:
        return Piece.VNKEI;
      case Piece.VGIN:
        return Piece.VNGIN;
      case Piece.VKAKU:
        return Piece.VNKAKU;
      case Piece.VHISYA:
        return Piece.VNHISYA;
      default:
        return Piece.NONE;
    }
  }
  Piece get unpromoted {
    switch (this) {
      case Piece.NFU:
        return Piece.FU;
      case Piece.NKYO:
        return Piece.KYO;
      case Piece.NKEI:
        return Piece.KEI;
      case Piece.NGIN:
        return Piece.GIN;
      case Piece.NKAKU:
        return Piece.KAKU;
      case Piece.NHISYA:
        return Piece.HISYA;
      case Piece.VNFU:
        return Piece.VFU;
      case Piece.VNKYO:
        return Piece.VKYO;
      case Piece.VNKEI:
        return Piece.VKEI;
      case Piece.VNGIN:
        return Piece.VGIN;
      case Piece.VNKAKU:
        return Piece.VKAKU;
      case Piece.VNHISYA:
        return Piece.VHISYA;
      default:
        return Piece.NONE;
    }
  }
  Piece get original {
    switch (this) {
      case Piece.NONE:
        return Piece.NONE;
      case Piece.EMPTY:
        return Piece.EMPTY;
      case Piece.EXIST:
        return Piece.EXIST;
      case Piece.FU:
        return Piece.FU;
      case Piece.KYO:
        return Piece.KYO;
      case Piece.KEI:
        return Piece.KEI;
      case Piece.GIN:
        return Piece.GIN;
      case Piece.KIN:
        return Piece.KIN;
      case Piece.KAKU:
        return Piece.KAKU;
      case Piece.HISYA:
        return Piece.HISYA;
      case Piece.OU:
        return Piece.OU;
      case Piece.GYOKU:
        return Piece.GYOKU;
      case Piece.NFU:
        return Piece.NFU;
      case Piece.NKYO:
        return Piece.NKYO;
      case Piece.NKEI:
        return Piece.NKEI;
      case Piece.NGIN:
        return Piece.NGIN;
      case Piece.NKAKU:
        return Piece.NKAKU;
      case Piece.NHISYA:
        return Piece.NHISYA;
      case Piece.VFU:
        return Piece.FU;
      case Piece.VKYO:
        return Piece.KYO;
      case Piece.VKEI:
        return Piece.KEI;
      case Piece.VGIN:
        return Piece.GIN;
      case Piece.VKIN:
        return Piece.KIN;
      case Piece.VKAKU:
        return Piece.KAKU;
      case Piece.VHISYA:
        return Piece.HISYA;
      case Piece.VOU:
        return Piece.OU;
      case Piece.VGYOKU:
        return Piece.GYOKU;
      case Piece.VNFU:
        return Piece.NFU;
      case Piece.VNKYO:
        return Piece.NKYO;
      case Piece.VNKEI:
        return Piece.NKEI;
      case Piece.VNGIN:
        return Piece.NGIN;
      case Piece.VNKAKU:
        return Piece.NKAKU;
      case Piece.VNHISYA:
        return Piece.NHISYA;
    }
  }
}