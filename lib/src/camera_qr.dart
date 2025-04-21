part of '../camera_custom.dart';

class CameraQr extends StatefulWidget {
  CameraLanguage language = const CameraLanguage();
  final Widget Function(BuildContext context)? build;

  CameraQr({super.key, this.build});

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
  bool _canProcess = true;
  bool _isBusy = false;
  bool onLoading = false;
  final _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
  List<Barcode> _barcodes = [];
  AnalysisImage? _image;

  // CameraController? cameraController;

  final lstByte = ValueNotifier<File?>(null);
  String value = "";

  @override
  void initState() {
    super.initState();
    handleQR();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraAwesomeBuilder.awesome(
            saveConfig: SaveConfig.photoAndVideo(
              initialCaptureMode: CaptureMode.photo,
            ),
            sensorConfig: SensorConfig.single(
              flashMode: FlashMode.auto,
              aspectRatio: CameraAspectRatios.ratio_16_9,
            ),
            previewFit: CameraPreviewFit.fitWidth,
            previewDecoratorBuilder: (state, preview) {
              return BarcodePreviewOverlay(
                state: state,
                barcodes: _barcodes,
                analysisImage: _image,
                preview: preview,
              );
            },
            topActionsBuilder: (state) {
              return SizedBox();
            },
            middleContentBuilder: (state) {
              return const SizedBox.shrink();
            },
            bottomActionsBuilder: (state) {
              return const SizedBox();
            },
            onImageForAnalysis: (img) => _processImageBarcode(img),
            imageAnalysisConfig: AnalysisConfig(
              androidOptions: const AndroidAnalysisOptions.nv21(
                width: 256,
              ),
              maxFramesPerSecond: 3,
            ),
          ),
          widget.build?.call(context) ??
              CustomPaint(
                painter: _PaintQR(),
                child: const Center(child: SizedBox()),
              ),
          // ValueListenableBuilder(
          //     valueListenable: lstByte,
          //     builder: (context, bytes, child) {
          //       return Column(
          //         crossAxisAlignment: CrossAxisAlignment.center,
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Text(value),
          //           if (bytes != null) Image.file(bytes),
          //         ],
          //       );
          //     }),
        ],
      ),
    );
  }

  Future _processImageBarcode(AnalysisImage img) async {
    try {
      var recognizedBarCodes = await _barcodeScanner.processImage(img.toInputImage());
      if (recognizedBarCodes.length == 1 && mounted) {
        Navigator.pop(context, recognizedBarCodes.firstOrNull?.rawValue);
      }
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    await _barcodeScanner.close();
  }

  void handleQR() async {
    //   try {
    //     while (mounted) {
    //       await Future.delayed(const Duration(milliseconds: 1000));
    //
    //       if (!mounted) return;
    //
    //       final xFile = await cameraController?.takePicture();
    //       if (xFile != null) {
    //         final img = await image.decodeImageFile(xFile.path);
    //         if (img != null && context.mounted) {
    //           final size = MediaQuery.sizeOf(context);
    //           final padding = MediaQuery.paddingOf(context);
    //           final heightImg = img.height;
    //           final widthImg = img.width;
    //           const sizeRatio = 1.5;
    //           final widthImage = widthImg ~/ sizeRatio;
    //           final heightImage = widthImg ~/ sizeRatio;
    //           final x = widthImg / 2 - widthImage / sizeRatio + (widthImage / sizeRatio * size.aspectRatio);
    //           final y = heightImg / 2 - heightImage / 2 - padding.top;
    //
    //           final imageCrop = image.copyCrop(
    //             img,
    //             x: x.toInt(),
    //             y: y.toInt(),
    //             width: (widthImage).toInt(),
    //             height: (heightImage).toInt(),
    //           );
    //
    //           final bytes = image.encodePng(imageCrop);
    //
    //           var file = File('${(await getApplicationCacheDirectory()).path}qr.jpg');
    //           await file.writeAsBytes(bytes);
    //
    //           final result = await _barcodeScanner.processImage(InputImage.fromFile(file));
    //
    //           await file.delete();
    //
    //           if (result.length == 1 && mounted) {
    //             Navigator.pop(context, result.firstOrNull?.rawValue);
    //           }
    //         }
    //       }
    //     }
    //   } catch (e, s) {
    //     _barcodeScanner = BarcodeScanner();
    //     print(e);
    //     print(s);
    //   }
    //   _canProcess = false;
    //   await _barcodeScanner.close();
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
