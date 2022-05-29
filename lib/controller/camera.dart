import 'dart:async';
import 'dart:ffi';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

class Camera extends StatefulWidget {
  final CameraController controller;
  final Completer<String> initializeCompleter;
  const Camera({Key? key, required this.controller, required this.initializeCompleter}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.value.isInitialized){
      widget.controller.initialize().then((_) {
        widget.controller.setFlashMode(FlashMode.torch);
        if (!mounted) {
          return;
        }
        widget.initializeCompleter.complete("initialized");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return Container();
    }

    return AspectRatio(
      aspectRatio: 1/widget.controller.value.aspectRatio,
      child: CameraPreview(widget.controller),
    );
  }

  @override
  void dispose() {
    // widget.controller.dispose();
    super.dispose();
  }
}
