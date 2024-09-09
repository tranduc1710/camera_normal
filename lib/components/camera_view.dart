part of '../camera_custom.dart';

class CameraView extends StatefulWidget {
  final Widget? child;
  final CameraLanguage language;
  final ImageFormatGroup imageFormatGroup;
  final ResolutionPreset resolutionPreset;
  final FlashMode flashMode;
  Function(CameraImage image)? startImageStream;
  final void Function(CameraController controller)? onInit;
  final bool isFullScreen;

  final Widget Function()? buildLoading;

  CameraView({
    super.key,
    this.language = const CameraLanguage(),
    this.child,
    this.onInit,
    this.imageFormatGroup = ImageFormatGroup.jpeg,
    this.resolutionPreset = ResolutionPreset.max,
    this.flashMode = FlashMode.auto,
    this.startImageStream,
    this.buildLoading,
    this.isFullScreen = true,
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
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      cameraController?.pausePreview();
    } else if (Platform.isIOS) {
      cameraController?.resumePreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future(() => initCamera(context)),
      builder: (context, snapshot) {
        final size = MediaQuery.of(context).size;

        if (snapshot.connectionState != ConnectionState.done || cameraController == null) return (widget.buildLoading?.call() ?? buildLoadingCamera());

        if (contentError.isNotEmpty) return buildError();

        if (!widget.isFullScreen) {
          return Center(
            child: CameraPreview(
              cameraController!,
              child: widget.child,
            ),
          );
        }

        return Center(
          child: Transform.scale(
            scale: size.aspectRatio + 1,
            child: AspectRatio(
              aspectRatio: (cameraController?.value.previewSize?.height ?? 4) / (cameraController?.value.previewSize?.width ?? 3),
              child: CameraPreview(
                cameraController!,
                child: widget.child,
              ),
            ),
          ),
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

  Widget buildLoadingCamera() {
    return Container();
  }

  Future<void> initCamera(BuildContext context, [CameraDescription? description]) async {
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
