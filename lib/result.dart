import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Result extends StatefulWidget {
  const Result({Key? key}) : super(key: key);

  @override
  _ResultState createState() => _ResultState();
}

class _ResultState extends State<Result> {
  File? imageFile;
  Image? image;

  Widget imageOrIcon() {
    if (image == null) {
      return const Icon(Icons.no_sim);
    }
    else {
      return image!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('棋譜記録結果'),
      ),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('１手目まで　先手勝ち'),
              imageOrIcon(),
              Container(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  child: const Text('最初に戻る'),
                  onPressed: () {
                    //　初期画面に戻る(4画面前)
                    int count = 0;
                    Navigator.popUntil(context, (_) => count++ >= 4);
                  },
                )
              ),
            ],
          ),
        )
      )
    );
  }
}
