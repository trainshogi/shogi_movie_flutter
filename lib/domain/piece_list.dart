import 'package:shogi_movie_flutter/domain/piece.dart';

List<Piece> firstPieceList = [
  Piece.FU, Piece.KYO, Piece.KEI, Piece.GIN, Piece.KIN,
  Piece.KAKU, Piece.HISYA, Piece.OU, Piece.GYOKU,
  Piece.NFU, Piece.NKYO, Piece.NKEI, Piece.NGIN,
  Piece.NKAKU, Piece.NHISYA
];

List<Piece> secondPieceList = [
  Piece.VFU, Piece.VKYO, Piece.VKEI, Piece.VGIN, Piece.VKIN,
  Piece.VKAKU, Piece.VHISYA, Piece.VOU, Piece.VGYOKU,
  Piece.VNFU, Piece.VNKYO, Piece.VNKEI, Piece.VNGIN,
  Piece.VNKAKU, Piece.VNHISYA
];

List<Piece> firstNonPromotedPieceList = [
  Piece.FU, Piece.KYO, Piece.KEI, Piece.GIN, Piece.KIN,
  Piece.KAKU, Piece.HISYA, Piece.OU, Piece.GYOKU];

List<Piece> secondNonPromotedPieceList = [
  Piece.VFU, Piece.VKYO, Piece.VKEI, Piece.VGIN, Piece.VKIN,
  Piece.VKAKU, Piece.VHISYA, Piece.VOU, Piece.VGYOKU];