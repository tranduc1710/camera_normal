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
  final scaffoldState = GlobalKey<ScaffoldState>();
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _canProcess = true;
  bool _isBusy = false;
  final content = ValueNotifier("");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _canProcess = false;
    _barcodeScanner.close();
    content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      key: scaffoldState,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: size.width / 2,
              height: size.width / 2,
              child: CameraView(
                language: widget.language,
                imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
                resolutionPreset: ResolutionPreset.low,
                startImageStream: (image) => startImageStream(context, image),
                onInit: (controller) {
                  controller.setZoomLevel(2);
                },
              ),
            ),
          ),
          CustomPaint(
            painter: _PaintQR(),
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -.33),
                  child: ValueListenableBuilder(
                      valueListenable: content,
                      builder: (context, value, child) {
                        return Text(
                          value.isEmpty ? widget.language.scanQR : value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      }),
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
                    onPressed: () => _onChoiceImage(context),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onChoiceImage(BuildContext context) async {
    final path = await _SelectImage().show(
      context,
      widget.language,
      scaffoldState.currentState!,
      hasConfirm: false,
    );
    if (path is String) {
      detectImage(context, InputImage.fromFile(File(path)));
    }
  }

  Future<void> detectImage(BuildContext context, InputImage inputImage, {bool showError = true}) async {
    final result = await _barcodeScanner.processImage(
      inputImage,
    );
    if (_canProcess) {
      content.value = '';
      if (result.isEmpty) {
        if (!showError) return;
        return _DialogAlert(widget.language).show(
          context,
          content: widget.language.noQrInImage,
        );
      }

      if (result.length > 1) {
        content.value = widget.language.toMuchQr;
        return;
      }

      if (Navigator.canPop(context)) {
        Navigator.pop(context, result.firstOrNull?.rawValue);
      }
    }
  }

  void startImageStream(BuildContext context, CameraImage image) async {
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
      await detectImage(context, inputImage, showError: false);
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
    paint.color = Colors.black;
    paint.strokeWidth = 2;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
