part of '../camera_custom.dart';

class CameraCustom extends StatefulWidget {
  final CameraView cameraView;
  final CameraCustomController? controller;

  final CameraLanguage? language;
  final Widget Function(BuildContext context, CameraView cameraView)? builder;

  const CameraCustom({
    super.key,
    required this.cameraView,
    this.builder,
    this.controller,
    this.language,
  });

  @override
  State<CameraCustom> createState() => _CameraCustomState();
}

class _CameraCustomState extends State<CameraCustom> {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();

  bool _canProcess = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.openChoiceImage = _onChoiceImage;
    widget.cameraView.startImageStream = startImageStream;
  }

  @override
  void dispose() async {
    _canProcess = false;
    super.dispose();
    await _barcodeScanner.close();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder?.call(context, widget.cameraView) ?? widget.cameraView;
  }

  void _onChoiceImage(BuildContext context) async {
    if (widget.controller == null) {
      if (kDebugMode) {
        print('No GlobalKey<ScaffoldState>? globalKey in controller');
      }
      return null;
    }
    final path = await SelectImage().show(
      context,
      widget.language ?? CameraLanguage(),
      // widget.controller!.globalKey!.currentState!,
      hasConfirm: false,
    );
    if (path is String) {
      detectImage(InputImage.fromFile(File(path)));
    }
  }

  Future<void> detectImage(InputImage inputImage) async {
    final result = await _barcodeScanner.processImage(
      inputImage,
    );
    if (_canProcess) {
      _canProcess = false;
      if (result.isEmpty) {
        _canProcess = true;
        widget.controller?.onError?.call(CameraCustomError.noQr);
        return;
      }

      if (result.length > 1) {
        _canProcess = true;
        widget.controller?.onError?.call(CameraCustomError.multiQr);
        return;
      }
      super.dispose();
      await _barcodeScanner.close();
      widget.controller?.onScanQr?.call(result.firstOrNull?.rawValue);
    }
  }

  void startImageStream(CameraImage image) async {
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
      await detectImage(inputImage);
    } catch (e, s) {
      if (kDebugMode) {
        print(e);
        print(s);
      }
    }
    _isBusy = false;
  }
}

class CameraCustomController {
  final GlobalKey<ScaffoldState>? globalKey;
  void Function(String? result)? onScanQr;
  void Function(CameraCustomError error)? onError;

  void Function(BuildContext context)? openChoiceImage;

  CameraCustomController({
    this.onScanQr,
    this.globalKey,
    this.onError,
  });
}

enum CameraCustomError {
  noQr,
  multiQr,
}
