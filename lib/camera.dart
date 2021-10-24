import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

class Camera extends StatefulWidget {
  final CameraController controller;
  const Camera({Key? key, required this.controller}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
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
