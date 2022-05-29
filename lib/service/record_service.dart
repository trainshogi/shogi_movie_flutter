import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:shogi_movie_flutter/repository/record_repository.dart';

import '../controller/audio_controller.dart';
import '../controller/file_controller.dart';
import '../domain/board.dart';
import '../domain/board_state.dart';
import '../domain/piece.dart';
import '../domain/piece_list.dart';
import '../util/util_sfen.dart';
import '../util/util_widget.dart';

class RecordService {
  FileController fileController = FileController();
  AudioController audioController = AudioController();
  late RecordRepository recordRepository;

  RecordService(String dirName) {
    recordRepository = RecordRepository(dirName);
  }

  Future<String> detectPiecePlace(BuildContext context, File savedFile, List<Offset> relativePoints) {
    if (relativePoints.length != 4) {
      alertDialog(context, "枠の角を4点設定してください");
      Completer<String> completer = Completer<String>();
      completer.complete("");
      return completer.future;
    }
    return recordRepository.initialPieceDetect(savedFile.path, relativePoints).then((result) {
      String currentSfen = result['sfen'];
      // if currentSfen is not correct, retake piece photo or give up
      if (!isInitialPosition(currentSfen)) {
        alertDialog(context, "初期盤面が正しく読み込まれませんでした。初期盤面を撮り直すか駒を撮り直してください。");
        return "";
      }
      successDialog(context, "初期盤面が正しく読み込まれました");
      return currentSfen;
    });
  }

  Future<void> recognize(BuildContext context, CameraController controller, BoardState boardState) async {
    // take picture
    return controller.takePicture().then((value) {
    // fileController.getImgFile(_savedImage).then((value) {
      // ImagePicker().pickImage(source: ImageSource.gallery).then((value) {
      String imageFilePath = value.path;
      // recognize image
      // FileController.directoryPath(widget.dirName).then((value) async {
        // get piece place
      return recordRepository.getPiecePlace(imageFilePath, boardState.relativePoints).then((map) async {
        String piecePlace = map["sfen"];
        // print(detectPlaceJson.toString());

        // detect movement
        Map<String, int> moveMap = getMovement(boardState.currentPiecePlace, piecePlace);

        // detect piece
        int prevSpace = moveMap["prevSpace"]!;
        int nextSpace = moveMap["nextSpace"]!;
        Piece prevPiece = (prevSpace != -1) ? boardState.board.board[prevSpace~/10][prevSpace%10] : Piece.NONE;
        Piece nextPiece;
        bool nari = false;
        Piece piece;
        String movePattern = "";
        if (prevSpace > -1 && nextSpace > -1) {
          // if user moves piece, just detect nextSpace's piece
          movePattern = "move";
          piece = prevPiece;
          String pieceNames = (prevPiece.promoted == Piece.NONE)
              ? prevPiece.english : prevPiece.english + "," + prevPiece.promoted.english;
          Map<String, dynamic> detectPieceJson = await recordRepository.onePieceDetect(
              imageFilePath, boardState.relativePoints, moveMap, pieceNames);
          nextPiece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
          // if prevPiece and nextPiece is different, it is "nari"
          nari = (prevPiece != nextPiece) ? true : false;
        }
        else if (nextSpace > -1) {
          // if user put piece, just detect nextSpace's piece
          movePattern = "put";
          String pieceNames = (boardState.currentMoveNumber%2 == 0)
              ? firstNonPromotedPieceList.map((Piece p) => p.english).toList().join(",")
              : secondNonPromotedPieceList.map((Piece p) => p.english).toList().join(",");
          Map<String, dynamic> detectPieceJson = await recordRepository.onePieceDetect(
              imageFilePath, boardState.relativePoints, moveMap, pieceNames);
          piece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
          nextPiece = Piece.values.firstWhere((e) => e.english == detectPieceJson["piece"]);
        }
        else {
          // if user take piece, search all pieces and get diff
          movePattern = "take";
          piece = prevPiece;
          String pieceNames = (prevPiece.promoted == Piece.NONE)
              ? prevPiece.english : prevPiece.english + "," + prevPiece.promoted.english;
          print(pieceNames);
          print(boardState.board.toSfen());
          Map<String, dynamic> detectPieceJson = await recordRepository.allPieceDetect(
              imageFilePath, boardState.relativePoints, boardState.board, pieceNames);
          Board detectedBoard = Board().fromSfen(detectPieceJson["sfen"]);
          Map<String, int> moveMap = getMovementWithBoard(boardState.board, detectedBoard);
          nextSpace = moveMap["nextSpace"]!;
          nextPiece = detectedBoard.board[nextSpace~/10][nextSpace%10];
          // if prevPiece and nextPiece is different, it is "nari"
          nari = (prevPiece != nextPiece) ? true : false;
        }

        // setState(() {
          boardState.currentMoveNumber += 1;
          updateBoard(prevSpace, nextSpace, piece, boardState.board, nari);
          boardState.currentKif = createKif(prevSpace, nextSpace, piece, boardState.board, nari);
          boardState.sfenMoveList.add(createSfenMove(prevSpace, nextSpace, piece, boardState.board, nari));
          boardState.currentPiecePlace = piecePlace;
        // });

        // play sounds
        List<String> filenames = createAudioFilenameList(prevSpace, nextSpace, piece, boardState.board, movePattern, nari);
        audioController.play(filenames);
      });
    });
  }
}