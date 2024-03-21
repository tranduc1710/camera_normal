part of '../camera_custom.dart';

class CameraQr extends StatefulWidget {
  CameraLanguage language = CameraLanguage();

  CameraQr({super.key});

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
  _CameraQrState createState() => _CameraQrState();
}

class _CameraQrState extends State<CameraQr> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: CameraView(
        language: widget.language,
        child: CustomPaint(
          painter: _PaintQR(),
          child: Stack(
            children: [
              Align(
                alignment: const Alignment(0, -.33),
                child: Text(
                  widget.language.scanQR,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0, .4),
                child: FilledButton(
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Colors.white),
                    foregroundColor: MaterialStatePropertyAll(Colors.grey),
                    shape: MaterialStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        side: BorderSide(width: 1, color: Colors.grey),
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.image_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.language.choiceImageFromGallery,
                        style: TextStyle(
                          color: Colors.black.withOpacity(.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaintQR extends CustomPainter {
  final radius = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final sizeFrameQR = size.width / 2;
    final path = Path();

    path.lineTo(size.width, 0);
    path.lineTo(
      size.width,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2 - sizeFrameQR / 2 + radius,
    );
    path.quadraticBezierTo(
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2 - sizeFrameQR / 2,
      size.width / 2 + sizeFrameQR / 2 - radius,
      size.height / 2 - sizeFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 - sizeFrameQR / 2 + radius,
      size.height / 2 - sizeFrameQR / 2,
    );
    path.quadraticBezierTo(
      size.width / 2 - sizeFrameQR / 2,
      size.height / 2 - sizeFrameQR / 2,
      size.width / 2 - sizeFrameQR / 2,
      size.height / 2 - sizeFrameQR / 2 + radius,
    );
    path.lineTo(
      size.width / 2 - sizeFrameQR / 2,
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
      size.width / 2 - sizeFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width / 2 - sizeFrameQR / 2,
      size.height / 2 + sizeFrameQR / 2 - radius,
    );
    path.quadraticBezierTo(
      size.width / 2 - sizeFrameQR / 2,
      size.height / 2 + sizeFrameQR / 2,
      size.width / 2 - sizeFrameQR / 2 + radius,
      size.height / 2 + sizeFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2 - radius,
      size.height / 2 + sizeFrameQR / 2,
    );
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2 - radius,
      size.height,
    );
    path.close();
    path.moveTo(
      size.width,
      size.height,
    );
    path.lineTo(size.width / 2, size.height);
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2 - radius,
      size.height / 2 + sizeFrameQR / 2,
    );
    path.quadraticBezierTo(
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2 + sizeFrameQR / 2,
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2 + sizeFrameQR / 2 - radius,
    );
    path.lineTo(
      size.width / 2 + sizeFrameQR / 2,
      size.height / 2,
    );
    path.lineTo(
      size.width,
      size.height / 2,
    );
    path.close();

    final paint = Paint();
    paint.color = Colors.black87;
    paint.strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
