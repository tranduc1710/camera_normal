part of '../camera_custom.dart';

class CameraQr extends StatefulWidget {
  CameraLanguage language = const CameraLanguage();
  final Widget Function(BuildContext context)? build;

  CameraQr({super.key, this.build});

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

  Future<List<Barcode>> detectImage(BuildContext context, InputImage inputImage) async {
    final BarcodeScanner barcodeScanner = BarcodeScanner();
    final result = await barcodeScanner.processImage(inputImage);
    await barcodeScanner.close();
    return result;
  }

  @override
  _CameraQrState createState() => _CameraQrState();
}

class _CameraQrState extends State<CameraQr> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  late final timer = Timer(
    const Duration(seconds: 1),
    () {
      _canScan = true;
    },
  );

  bool _canProcess = true;
  bool _isBusy = false;
  bool _canScan = false;

  @override
  void dispose() async {
    _canProcess = false;
    timer.cancel();
    await _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraView(
            language: widget.language,
            imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
            resolutionPreset: ResolutionPreset.low,
            startImageStream: (image) => startImageStream(context, image),
          ),
          CustomPaint(
            painter: _PaintQR(),
            child: widget.build?.call(context),
          ),
        ],
      ),
    );
  }

  Future<void> detectImage(BuildContext context, InputImage inputImage) async {
    final result = await _barcodeScanner.processImage(
      inputImage,
    );
    if (_canProcess) {
      _canProcess = false;
      if (result.isEmpty) {
        _canProcess = true;
        return;
      }

      if (result.length > 1) {
        _canProcess = true;
        return;
      }
      super.dispose();
      await _barcodeScanner.close();

      if (context.mounted) {
        Navigator.pop(context, result.firstOrNull?.rawValue);
      }
    }
  }

  void startImageStream(BuildContext context, CameraImage image) async {
    if (!_canScan) return;
    _canScan = false;
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    try {
      // get image format
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      // validate format depending on platform
      // only supported formats:
      // * nv21 for Android
      // * bgra8888 for iOS
      if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
        return;
      }

      // since format is constraint to nv21 or bgra8888, both only have one plane
      if (image.planes.length != 1) return;
      final plane = image.planes.first;

      // compose InputImage using bytes
      final inputImage = InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg, // used only in Android
          format: format, // used only in iOS
          bytesPerRow: plane.bytesPerRow, // used only in iOS
        ),
      );
      await detectImage(context, inputImage);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    _isBusy = false;
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
    paint.color = Colors.black26;
    paint.strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
