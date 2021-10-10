import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shogi_movie_flutter/base_img_setting.dart';
import 'package:shogi_movie_flutter/util.dart';

class PieceSelect extends StatefulWidget {
  const PieceSelect({Key? key}) : super(key: key);

  @override
  _PieceSelectState createState() => _PieceSelectState();
}

class _PieceSelectState extends State<PieceSelect> {

  List<Widget> savedPieceWidgetList = [];

  Future<void> getSavedPieceWidgetList() async {
    List<Widget> widgetList = [];
    Map<String, bool> savedPieceList = await getSavedPieceNameMap();
    savedPieceList.forEach((key, value) {
      if (value) widgetList.add(savedPieceWidget(key));
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => BaseImgSetting(dirName: text)),
            );
          },
        )),
      ],
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
        title: const Text('駒選択'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: savedPieceWidgetList
        ),
      )
    );
  }
}
