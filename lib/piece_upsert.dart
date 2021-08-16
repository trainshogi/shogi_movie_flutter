import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'file_controller.dart';

class PieceUpsert extends StatefulWidget {
  const PieceUpsert({Key? key}) : super(key: key);

  @override
  _PieceUpsertState createState() => _PieceUpsertState();
}

class _PieceUpsertState extends State<PieceUpsert> {

  String pieceNameJapanese = "歩";
  File? imageFile;

  void _getAndSaveImageFromDevice(ImageSource source) async {
    // 撮影/選択したFileが返ってくる
    final ImagePicker _picker = ImagePicker();
    var imageFile = await _picker.pickImage(source: source);
    // 撮影せずに閉じた場合はnullになる
    if (imageFile == null) {
      return;
    }

    var savedFile = await FileController.saveLocalImage(imageFile, 'fu.jpg'); //追加

    setState(() {
      // this.imageFile = imageFile;
      this.imageFile = savedFile; //変更
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: (imageFile == null)
                    ? const Icon(Icons.no_sim)
                    : Image.memory(imageFile!.readAsBytesSync()),
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('カメラで撮影'),
                  onPressed: () {
                    _getAndSaveImageFromDevice(ImageSource.camera); // New Line
                  },
                )),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('ライブラリから選択'),
                  onPressed: () {},
                )),
            ],
          ),
        )
      )
    );
  }
}
