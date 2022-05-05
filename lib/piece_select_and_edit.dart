import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/piece_upsert.dart';
import 'package:shogi_movie_flutter/util/util.dart';
import 'package:shogi_movie_flutter/util/util_widget.dart';

import 'controller/file_controller.dart';

class PieceSelectAndEdit extends StatefulWidget {
  const PieceSelectAndEdit({Key? key}) : super(key: key);

  @override
  _PieceSelectAndEditState createState() => _PieceSelectAndEditState();
}

class _PieceSelectAndEditState extends State<PieceSelectAndEdit> {
  List<Widget> savedPieceWidgetList = [];

  Future<void> getSavedPieceWidgetList() async {
    List<Widget> widgetList = [];
    Map<String, bool> savedPieceList = await getSavedPieceNameMap();
    savedPieceList.forEach((key, value) {
      widgetList.add(savedPieceWidget(key));
    });
    setState(() {
      savedPieceWidgetList = widgetList;
    });
  }

  Widget savedPieceWidget(String text) {
    return Row(
      children: [
        Expanded(child: ElevatedButton(
          child: Text(text),
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            onPrimary: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
          },
        )),
        ElevatedButton(
          child: const Text('変更'),
          style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PieceUpsert(dirName: text)),
            );
          },
        ),
        ElevatedButton(
          child: const Text('削除'),
          style: ElevatedButton.styleFrom(
            primary: Colors.blueAccent,
            onPrimary: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () {
            showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                      title: const Text('削除しても良いですか？'),
                      actions: <Widget>[
                        ElevatedButton(
                            child: const Text('キャンセル'),
                            onPressed: () {
                              Navigator.pop(context);
                            }),
                        ElevatedButton(
                            child: const Text('はい'),
                            onPressed: () async {
                              await FileController.deleteFolder(text);
                              Navigator.pop(context);
                              successDialog(context, "削除しました");
                              setState(() {
                                getSavedPieceWidgetList();
                              });
                            }),
                      ]
                  );
                }
            );
          },
        ),
      ],
    );
  }

  Widget plusButton() {
    var _pieceNameController = TextEditingController();
    return ElevatedButton(
      child: const Text('追加'),
      style: ElevatedButton.styleFrom(
        primary: Colors.blueAccent,
        onPrimary: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
                title: const Text('駒の名前を入力してください。'),
                content: TextField(
                  controller: _pieceNameController,
                  decoration: const InputDecoration(hintText: '駒1'),
                  autofocus: true,
                ),
                actions: <Widget>[
                  ElevatedButton(
                      child: const Text('キャンセル'),
                      onPressed: () {
                        Navigator.pop(context);
                      }),
                  ElevatedButton(
                      child: const Text('追加'),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) =>
                              PieceUpsert(dirName: _pieceNameController.text)),
                        );
                      }),
                ]
            );
          }
        );
      },
    );
  }

  Widget reloadButton() {
    return Ink(
      decoration: const ShapeDecoration(
        color: Colors.blueAccent,
        shape: CircleBorder(),
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh),
        color: Colors.white,
        onPressed: () {
          setState(() {
            getSavedPieceWidgetList();
          });
        },
      ),
    );
  }

  @override
  void initState(){
    getSavedPieceWidgetList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('編集駒選択'),
      ),
      body: Stack(children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: savedPieceWidgetList
          ),
        ),
        Positioned(
          top: 10.0,
          right: 10.0,
          child: reloadButton(),
        ),
        Positioned(
          bottom: 10.0,
          right: 10.0,
          child: plusButton(),
        ),
      ])
    );
  }
}
