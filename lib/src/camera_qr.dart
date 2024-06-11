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

  bool _canProcess = true;
  bool _isBusy = false;
  bool onLoading = false;
  CameraController? cameraController;
  late Timer timer;

  final lstByte = ValueNotifier<File?>(null);
  String value = "";

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) async {
        if (onLoading) return;
        onLoading = true;
        try {
          final xFile = await cameraController?.takePicture();
          if (xFile != null) {
            final img = await image.decodeImageFile(xFile.path);
            if (img != null && context.mounted) {
              final size = MediaQuery.sizeOf(context);
              final padding = MediaQuery.paddingOf(context);
              final heightImg = img.height;
              final widthImg = img.width;
              final widthImage = widthImg ~/ 2;
              final heightImage = widthImg ~/ 2;

              final imageCrop = image.copyCrop(
                img,
                x: (widthImg / 2 - widthImage / 2 + (widthImage / 2 * size.aspectRatio)).toInt(),
                y: (heightImg / 2 - heightImage / 2 + (heightImage * size.aspectRatio) + padding.top).toInt(),
                width: (widthImage * size.aspectRatio).toInt(),
                height: (heightImage * size.aspectRatio).toInt(),
              );

              final bytes = image.encodePng(imageCrop);

              var file = File('${(await getApplicationCacheDirectory()).path}qr.jpg');
              await file.writeAsBytes(bytes);

              final result = await _barcodeScanner.processImage(InputImage.fromFile(file));

              await file.delete();

              if (result.length == 1) {
                timer.cancel();
                Navigator.pop(context, result.firstOrNull?.rawValue);
              }
            }
          }
        } catch (e, s) {
          print(e);
          print(s);
        }
        onLoading = false;
      },
    );
  }

  @override
  void dispose() async {
    _canProcess = false;
    timer.cancel();
    super.dispose();
    await _barcodeScanner.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraView(
            // isFullScreen: false,
            language: widget.language,
            imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
            resolutionPreset: ResolutionPreset.medium,
            onInit: (controller) {
              cameraController = controller;
              cameraController?.setFlashMode(FlashMode.off);
            },
            // startImageStream: (image) => startImageStream(context, image),
          ),
          CustomPaint(
            painter: _PaintQR(),
            child: widget.build?.call(context) ?? const Center(child: SizedBox()),
          ),
          ValueListenableBuilder(
              valueListenable: lstByte,
              builder: (context, bytes, child) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(value),
                    if (bytes != null) Image.file(bytes),
                  ],
                );
              }),
        ],
      ),
    );
  }

  Future<void> detectImage(BuildContext context, InputImage inputImage) async {
    image.Image? imageCrop;

    if (inputImage.bytes != null) {
      final img = image.decodeImage(inputImage.bytes!);
      if (img != null) {
        final heightImg = img.height;
        final widthImg = img.width;
        final widthImage = widthImg ~/ 2;
        final heightImage = widthImg ~/ 2;

        imageCrop = image.copyCrop(
          img,
          x: widthImg ~/ 2 - widthImage ~/ 2,
          y: heightImg ~/ 2 - heightImage,
          width: widthImage ~/ 2,
          height: heightImage ~/ 2,
        );
        inputImage = InputImage.fromBytes(
            bytes: image.encodePng(imageCrop),
            metadata: InputImageMetadata(
              size: Size(widthImage.toDouble(), heightImage.toDouble()),
              rotation: InputImageRotation.rotation0deg,
              format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
              bytesPerRow: imageCrop.bitsPerChannel,
            ));
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    final result = await _barcodeScanner.processImage(inputImage);
    if (_canProcess) {
      _canProcess = false;
      if (result.isEmpty) {
        _canProcess = true;
        value = '';
        return;
      }

      if (result.length > 1) {
        _canProcess = true;
        value = '';
        return;
      }

      if (value.isNotEmpty && value == result.firstOrNull?.rawValue) {
        print(value);
        if (imageCrop != null) {
          final base64 = base64Encode(imageCrop.getBytes());
          print(base64);
        }
        // Navigator.pop(context);
        // return;
      }

      value = result.firstOrNull?.rawValue ?? '';
      _canProcess = true;
    } else {
      value = '';
    }
  }

  void startImageStream(BuildContext context, CameraImage image) async {
    // if (!_canScan) return;
    // _canScan = false;
    await Future.delayed(const Duration(seconds: 1));
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
