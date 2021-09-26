import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/result.dart';

class Record extends StatefulWidget {
  final String dirName;
  const Record({Key? key, required this.dirName}) : super(key: key);

  @override
  _RecordState createState() => _RecordState();
}

class _RecordState extends State<Record> {
  File? imageFile;
  Image? image;
  final AudioCache _player = AudioCache(fixedPlayer: AudioPlayer());

  Widget imageOrIcon() {
    if (image == null) {
      return const Icon(Icons.no_sim);
    }
    else {
      return image!;
    }
  }

  @override
  void initState(){
    super.initState();
    _player.load("sounds/initial.mp3");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('棋譜記録'),
        ),
        body: Center(
            child: Container(
              alignment: Alignment.center,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('１手目：７六歩'),
                  imageOrIcon(),
                  Container(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        child: const Text('投了'),
                        onPressed: () {
                          _player.play("sounds/initial.mp3");
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(builder: (context) => const Result()),
                          // );
                        },
                      )),
                ],
              ),
            )
        )
    );
  }
}
