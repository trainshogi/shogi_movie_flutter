import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shogi_movie_flutter/util/util_sfen.dart';

class Result extends StatefulWidget {
  final int moveNumber;
  final String winner;
  final String sfen;
  const Result({Key? key, required this.moveNumber, required this.winner, required this.sfen}) : super(key: key);

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
              Text(widget.moveNumber.toString() + '手目まで　' + widget.winner),
              imageOrIcon(),
              ElevatedButton(
                child: const Text('KENTOで検討'),
                onPressed: () async {
                  if (await canLaunch(sfen2KentoLink(widget.sfen))) {
                    await launch(sfen2KentoLink(widget.sfen));
                  }
                }
              ),
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
