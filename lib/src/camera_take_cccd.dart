part of '../camera_custom.dart';

class CameraTakeCIC extends StatefulWidget {
  CameraLanguage language = const CameraLanguage();
  final Widget Function(BuildContext context) build;
  void Function(CameraController)? onSetController;
  final Color? background;

  CameraTakeCIC({
    Key? key,
    required this.build,
    required this.onSetController,
    this.background,
  }) : super(key: key);

  Future<String?> show(BuildContext context, [CameraLanguage? language]) async {
    if (language != null) {
      this.language = language;
    }

    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => this));

    if (result is String) {
      return result;
    }
    return null;
  }

  @override
  _CameraTakeCICState createState() => _CameraTakeCICState();
}

class _CameraTakeCICState extends State<CameraTakeCIC> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: CameraView(
              isFullScreen: false,
              language: widget.language,
              resolutionPreset: ResolutionPreset.medium,
              imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
              onInit: widget.onSetController,
            ),
          ),
          CustomPaint(
            painter: _PaintCCCD(widget.background ?? Colors.black),
            child: widget.build(context),
          ),
        ],
      ),
    );
  }
}

class _PaintCCCD extends CustomPainter {
  final Color background;

  _PaintCCCD(this.background);

  final radius = 10.0;

  @override
  void paint(Canvas canvas, Size size) {
    final widthFrameQR = size.width * .85;
    final heightFrameQR = size.width * .55;
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
    paint.color = background;
    paint.strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
