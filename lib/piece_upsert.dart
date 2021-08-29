import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shogi_movie_flutter/frame_painter.dart';

import 'file_controller.dart';

class PieceUpsert extends StatefulWidget {
  const PieceUpsert({Key? key}) : super(key: key);

  @override
  _PieceUpsertState createState() => _PieceUpsertState();
}

class _PieceUpsertState extends State<PieceUpsert> {

  // variables
  File? imageFile;
  Image? image;
  Image? transImage;
  int movePointIndex = 0;
  int pieceNameIndex = 0;
  String pieceNameJapanese = "歩兵";

  // static variables
  final pieceNameListJapanese = [
    "歩兵", "香車", "桂馬", "銀将", "金将", "角行", "飛車", "王将",
    "と金", "成香", "成桂", "成銀", "竜馬", "龍王"
  ];
  final pieceNameListEnglish = [
    "fu", "kyo", "kei", "gin", "kin", "kaku", "hisya", "ou",
    "nfu", "nkyo", "nkei", "ngin", "nkaku", "nhisya"
  ];

  // タッチした点を覚えておく
  final _points = <Offset>[];

  void _getImageFromDevice() async {
    File savedFile = await FileController.loadLocalImage(
        '駒1', pieceNameListEnglish[pieceNameIndex] + '.jpg');

    if (savedFile.existsSync()) {
      setState(() {
        // this.imageFile = imageFile;
        imageFile = savedFile; //変更
        image = Image.memory(savedFile.readAsBytesSync());
        transImage = Image.memory(
            savedFile.readAsBytesSync(),
            color: const Color.fromRGBO(255, 255, 255, 0)
        );
      });
    }
  }

  void _getAndSaveImageFromDevice(ImageSource source) async {
    // 撮影/選択したFileが返ってくる
    final ImagePicker _picker = ImagePicker();
    var imageFile = await _picker.pickImage(source: source);
    // 撮影せずに閉じた場合はnullになる
    if (imageFile == null) {
      return;
    }

    var savedFile = await FileController.saveLocalImage(
        imageFile, '駒1', pieceNameListEnglish[pieceNameIndex] + '.jpg'); //追加

    if (savedFile.existsSync()) {
      setState(() {
        // this.imageFile = imageFile;
        this.imageFile = savedFile; //変更
        image = Image.memory(savedFile.readAsBytesSync());
        transImage = Image.memory(
            savedFile.readAsBytesSync(),
            color: const Color.fromRGBO(255, 255, 255, 0)
        );
      });
    }
  }

  // 点を追加
  void _addPoint(TapUpDetails details) {
    // setState()にリストを更新する関数を渡して状態を更新
    setState(() {
      _points.add(details.localPosition);
    });
  }

  // singleTapに制御がいかないようにここは必要。
  void _catchDoubleTap() {
  }

  void _deletePoint(TapDownDetails details) {
    if (_points.isNotEmpty) {
      int removePointIndex = getNearestPointIndex(_points, details.localPosition);
      setState(() {
        _points.removeAt(removePointIndex);
      });
    }
  }

  void _setMovePointIndex(DragStartDetails details) {
    if (_points.isNotEmpty) {
      movePointIndex = getNearestPointIndex(_points, details.localPosition);
      setState(() {
        _points[movePointIndex] = details.localPosition;
      });
    }
  }

  void _movePoint(DragUpdateDetails details) {
    if (_points.isNotEmpty) {
      setState(() {
        _points[movePointIndex] = details.localPosition;
      });
    }
  }
  
  Widget imageAndPainter() {
    if (imageFile == null) {
      return const Icon(Icons.no_sim);
    }
    else {
      return Stack(
        children: [
          image!,
          GestureDetector(
            // 追加イベント
            onTapUp: _addPoint,
            // 削除イベント
            onDoubleTap: _catchDoubleTap,
            onDoubleTapDown: _deletePoint,
            // 移動イベント
            onPanStart: _setMovePointIndex,
            onPanUpdate: _movePoint,
            // カスタムペイント
            child: CustomPaint(
              painter: FramePainter(_points),
              // タッチを有効にするため、childが必要
              child: transImage,
            ),
          ),
        ],
      );
    }
  }

  void _showErrorAlertDialog(String text) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("エラー"),
          content: Text(text),
          actions: <Widget>[
            // ボタン領域
            TextButton(
              child: const Text("OK"),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _prevPieceButtonPushed() {
    if (imageFile == null) {
      _showErrorAlertDialog('駒の画像が設定されていません。');
    }
    else if (_points.length < 3) {
      _showErrorAlertDialog('駒の枠が設定されていません。');
    }
    else if (pieceNameIndex == 0) {
      _showErrorAlertDialog('前の駒は存在しません。');
    }
    else {
      setState(() {
        // initialize
        imageFile = null;
        image = null;
        transImage = null;
        _points.clear();
        // set index
        pieceNameIndex -= 1;
      });
      _getImageFromDevice();
    }
  }

  void _nextPieceButtonPushed() {
    if (imageFile == null) {
      _showErrorAlertDialog('駒の画像が設定されていません。');
    }
    else if (_points.length < 3) {
      _showErrorAlertDialog('駒の枠が設定されていません。');
    }
    else if (pieceNameIndex == pieceNameListJapanese.length - 1) {
      _showErrorAlertDialog('駒の設定が終了しました。');
    }
    else {
      setState(() {
        // initialize
        imageFile = null;
        image = null;
        transImage = null;
        _points.clear();
        // set index
        pieceNameIndex += 1;
      });
      _getImageFromDevice();
    }
  }

  @override
  void initState() {
    _getImageFromDevice();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('駒画像撮影・枠位置編集'),
      ),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Text(pieceNameListJapanese[pieceNameIndex] + 'の画像設定'),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: imageAndPainter(),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('カメラで撮影'),
                  onPressed: () {
                    _getAndSaveImageFromDevice(ImageSource.camera); // New Line
                  },
                )
              ),
              Row(
                children: [
                  Container(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        child: const Text('前の駒を設定'),
                        onPressed: () => _prevPieceButtonPushed(),
                      )
                  ),
                  Container(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        child: const Text('次の駒を設定'),
                        onPressed: () => _nextPieceButtonPushed(),
                      )
                  ),
                ],
              )
            ],
          ),
        )
      )
    );
  }
}