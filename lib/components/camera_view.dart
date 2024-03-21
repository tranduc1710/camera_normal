part of '../camera_custom.dart';

class CameraView extends StatefulWidget {
  final Widget? child;
  final CameraLanguage language;

  final Function(CameraController controller)? onInit;

  CameraView({
    super.key,
    required this.language,
    this.child,
    this.onInit,
  });

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<CameraView> {
  CameraController? cameraController;

  late List<CameraDescription> _cameras;

  var contentError = '';

  @override
  void dispose() {
    super.dispose();
    cameraController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FutureBuilder(
      future: initCamera(),
      builder: (context, snapshot) {
        return SizedBox(
          width: size.width,
          height: size.height,
          child: snapshot.connectionState != ConnectionState.done
              ? buildLoadingCamera()
              : contentError.isNotEmpty
                  ? buildError()
                  : CameraPreview(
                      cameraController!,
                      child: widget.child,
                    ),
        );
      },
    );
  }

  Center buildError() {
    return Center(
      child: Text(
        contentError,
        style: const TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }

  Center buildLoadingCamera() {
    return Center(
      child: Text(
        widget.language.contentLoadCamera,
        style: widget.language.styleLoadCamera ??
            const TextStyle(
              color: Colors.red,
            ),
      ),
    );
  }

  Future<void> initCamera([CameraDescription? description]) async {
    if (cameraController?.value.isInitialized ?? false) return;
    _cameras = await availableCameras();
    cameraController = CameraController(
      description ?? _cameras[0],
      ResolutionPreset.ultraHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    widget.onInit?.call(cameraController!);
    await cameraController?.initialize();
    cameraController?.setDescription(description ?? _cameras[0]);
    return;
  }
}
