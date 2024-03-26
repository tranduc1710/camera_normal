part of '../camera_custom.dart';

class CameraView extends StatefulWidget {
  final Widget? child;
  final CameraLanguage language;
  final ImageFormatGroup imageFormatGroup;
  final ResolutionPreset resolutionPreset;
  final FlashMode flashMode;
  final Function(CameraImage image)? startImageStream;
  final void Function(CameraController controller)? onInit;

  CameraView({
    super.key,
    required this.language,
    this.child,
    this.onInit,
    this.imageFormatGroup = ImageFormatGroup.jpeg,
    this.resolutionPreset = ResolutionPreset.max,
    this.flashMode = FlashMode.auto,
    this.startImageStream,
  });

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<CameraView> {
  CameraController? cameraController;

  late List<CameraDescription> _cameras;

  var contentError = '';

  @override
  void dispose() async {
    super.dispose();
    if (widget.startImageStream != null) {
      await cameraController?.stopImageStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initCamera(),
      builder: (context, snapshot) {
        return snapshot.connectionState != ConnectionState.done
            ? buildLoadingCamera()
            : contentError.isNotEmpty
                ? buildError()
                : CameraPreview(
                    cameraController!,
                    child: widget.child,
                  );
      },
    );
  }

  Scaffold buildError() {
    return Scaffold(
      body: Center(
        child: Text(
          contentError,
          style: const TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Scaffold buildLoadingCamera() {
    return Scaffold(
      body: Center(
        child: Text(
          widget.language.contentLoadCamera,
          style: widget.language.styleLoadCamera ??
              const TextStyle(
                color: Colors.red,
              ),
        ),
      ),
    );
  }

  Future<void> initCamera([CameraDescription? description]) async {
    if (cameraController?.value.isInitialized ?? false) return;
    _cameras = await availableCameras();
    cameraController = CameraController(
      description ?? _cameras[0],
      widget.resolutionPreset,
      enableAudio: false,
      imageFormatGroup: widget.imageFormatGroup,
    );
    await cameraController!.initialize();
    await cameraController!.setDescription(description ?? _cameras[0]);
    await cameraController!.setFlashMode(widget.flashMode);
    if (widget.startImageStream != null) {
      await cameraController!.startImageStream((image) => widget.startImageStream?.call(image));
    }
    widget.onInit?.call(cameraController!);
    return;
  }
}