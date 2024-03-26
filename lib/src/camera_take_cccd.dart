part of '../camera_custom.dart';

class CameraTakeCIC extends StatefulWidget {
  CameraLanguage language = CameraLanguage();

  CameraTakeCIC({Key? key}) : super(key: key);

  Future<String?> show(BuildContext context, [CameraLanguage? language]) async {
    if (language != null) {
      this.language = language;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => this,
      ),
    );

    if (result is String) {
      return result;
    }
    return null;
  }

  @override
  _CameraTakeCICState createState() => _CameraTakeCICState();
}

class _CameraTakeCICState extends State<CameraTakeCIC> {
  final notiBtnTake = ValueNotifier<bool>(false);
  CameraController? cameraController;

  final sizeBtn = 55.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: CameraView(
              language: widget.language,
              resolutionPreset: ResolutionPreset.medium,
              onInit: (controller) async {
                cameraController = controller;
              },
            ),
          ),
          CustomPaint(
            painter: _PaintCCCD(),
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -.33),
                  child: Text(
                    widget.language.citizenInFrame,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(.95, -.92),
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0, .9),
                  child: GestureDetector(
                    onTap: () => onTakePicture(context, size),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      width: sizeBtn + 5,
                      height: sizeBtn + 5,
                      child: ValueListenableBuilder(
                        valueListenable: notiBtnTake,
                        builder: (BuildContext context, value, Widget? child) {
                          if (value) {
                            return Center(
                              child: SizedBox(
                                width: sizeBtn - 10,
                                height: sizeBtn - 10,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }
                          return Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: sizeBtn / 2,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onTakePicture(BuildContext context, Size size) async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    try {
      final xFile = await cameraController?.takePicture();
      await cameraController?.pausePreview();
      if (xFile != null) {
        final widthFrameQR = 700.0 * size.aspectRatio;
        final heightFrameQR = 400.0 * size.aspectRatio;
        final aspectRatio = cameraController!.value.previewSize!.aspectRatio + size.aspectRatio / 2;
        final height2 = size.height - cameraController!.value.previewSize!.height;
        final img = await image.decodeImageFile(xFile.path);
        if (img != null) {
          final imageCrop = image.copyCrop(
            img,
            x: (size.width - widthFrameQR) ~/ 2,
            y: (cameraController!.value.previewSize!.height / 2 - height2 / 4).toInt(),
            width: (widthFrameQR * aspectRatio).toInt(),
            height: (heightFrameQR * aspectRatio).toInt(),
          );
          await File(xFile.path).writeAsBytes(image.encodePng(imageCrop));

          notiBtnTake.value = false;
          if (context.mounted) {
            final result = await _DialogAsk(context, widget.language).show(xFile.path, size);

            if (result is String && context.mounted) {
              Navigator.pop(context, result);
            }
          }
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
    }
    await cameraController?.resumePreview();
    notiBtnTake.value = false;
  }
}

class _PaintCCCD extends CustomPainter {
  final radius = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final widthFrameQR = 700.0 * size.aspectRatio;
    final heightFrameQR = 400.0 * size.aspectRatio;
    final path = Path();

    path.lineTo(size.width, 0);
    path.lineTo(
      size.width,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 + widthFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 + widthFrameQR / 2,
      size.height / 2 - heightFrameQR / 2 + radius,
    );
    path.quadraticBezierTo(
      size.width / 2 + widthFrameQR / 2,
      size.height / 2 - heightFrameQR / 2,
      size.width / 2 + widthFrameQR / 2 - radius,
      size.height / 2 - heightFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 - widthFrameQR / 2 + radius,
      size.height / 2 - heightFrameQR / 2,
    );
    path.quadraticBezierTo(
      size.width / 2 - widthFrameQR / 2,
      size.height / 2 - heightFrameQR / 2,
      size.width / 2 - widthFrameQR / 2,
      size.height / 2 - heightFrameQR / 2 + radius,
    );
    path.lineTo(
      size.width / 2 - widthFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      0,
      size.height / 2,
    );
    path.close();
    path.moveTo(
      0,
      size.height,
    );
    path.lineTo(
      0,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 - widthFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 - widthFrameQR / 2,
      size.height / 2 + heightFrameQR / 2 - radius,
    );
    path.quadraticBezierTo(
      size.width / 2 - widthFrameQR / 2,
      size.height / 2 + heightFrameQR / 2,
      size.width / 2 - widthFrameQR / 2 + radius,
      size.height / 2 + heightFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 + widthFrameQR / 2 - radius,
      size.height / 2 + heightFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 + widthFrameQR / 2 - radius,
      size.height,
    );
    path.close();
    path.moveTo(
      size.width,
      size.height,
    );
    path.lineTo(size.width / 2, size.height);
    path.lineTo(
      size.width / 2 + widthFrameQR / 2 - radius,
      size.height / 2 + heightFrameQR / 2,
    );
    path.quadraticBezierTo(
      size.width / 2 + widthFrameQR / 2,
      size.height / 2 + heightFrameQR / 2,
      size.width / 2 + widthFrameQR / 2,
      size.height / 2 + heightFrameQR / 2 - radius,
    );
    path.lineTo(
      size.width / 2 + widthFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width,
      size.height / 2,
    );
    path.close();

    final paint = Paint();
    paint.color = Colors.black;
    paint.strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
