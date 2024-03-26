part of '../camera_custom.dart';

class CameraNormal extends StatefulWidget {
  CameraLanguage language = CameraLanguage();

  CameraNormal({super.key});

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
  _CameraNormalState createState() => _CameraNormalState();
}

class _CameraNormalState extends State<CameraNormal> {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  final scaffoldState = GlobalKey<ScaffoldState>();

  final notiBtnTake = ValueNotifier<bool>(false);
  final notiPathRecent = ValueNotifier('');

  var notiFlashMode = ValueNotifier(FlashMode.auto);
  var isBackCamera = true;
  var contentError = '';
  var pathSaveFile = '';

  List<File> listPhoto = [];

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
    notiBtnTake.dispose();
    notiPathRecent.dispose();
    notiFlashMode.dispose();
    PhotoManager.clearFileCache();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      key: scaffoldState,
      backgroundColor: Colors.black,
      body: Column(
        children: [
          buildTop(context, size, padding),
          Expanded(
            child: Stack(
              children: [
                CameraView(
                  onInit: (controller) {
                    this.controller = controller;
                  },
                  language: widget.language,
                  child: GestureDetector(
                    onTapDown: (details) => onFocusCamera(size, details),
                  ),
                ),
                Positioned(
                  width: size.width,
                  bottom: 0,
                  child: buildBottom(context, size, padding),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Container buildTop(BuildContext context, Size size, EdgeInsets padding) {
    return Container(
      width: size.width,
      padding: EdgeInsets.only(top: padding.top),
      color: Colors.black,
      child: Row(
        children: [
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Icon(
              Icons.arrow_back_ios_new_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: setFlashMode,
            icon: ValueListenableBuilder(
                valueListenable: notiFlashMode,
                builder: (context, value, child) {
                  switch (value) {
                    case FlashMode.always:
                      return const Icon(
                        Icons.flash_on,
                        color: Colors.white,
                        size: 20,
                      );
                    case FlashMode.off:
                      return const Icon(
                        Icons.flash_off,
                        color: Colors.white,
                        size: 20,
                      );
                    default:
                      return const Icon(
                        Icons.flash_auto,
                        color: Colors.white,
                        size: 20,
                      );
                  }
                }),
          ),
        ],
      ),
    );
  }

  Container buildBottom(BuildContext context, Size size, EdgeInsets padding) {
    const sizeBtn = 55.0;

    return Container(
      color: Colors.black,
      width: size.width,
      padding: EdgeInsets.only(
        bottom: padding.bottom + 30,
        top: 15,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onShowRecentImage(context, size),
              child: Center(
                child: Container(
                  width: sizeBtn,
                  height: sizeBtn,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      width: 1,
                      color: Colors.grey,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: ValueListenableBuilder(
                      valueListenable: notiPathRecent,
                      builder: (context, value, child) {
                        if (value.isEmpty) {
                          return const Icon(Icons.image_outlined).shimmer(
                            size,
                            true,
                          );
                        }
                        return Image.file(
                          File(value),
                          fit: BoxFit.cover,
                          width: sizeBtn,
                          height: sizeBtn,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => onTakePicture(context, size),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  width: sizeBtn + 5,
                  height: sizeBtn + 5,
                  child: ValueListenableBuilder(
                    valueListenable: notiBtnTake,
                    builder: (BuildContext context, value, Widget? child) {
                      if (value) {
                        return const Center(
                          child: SizedBox(
                            width: sizeBtn - 10,
                            height: sizeBtn - 10,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: sizeBtn / 2,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: onSwitchCamera,
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
                    Icons.flip_camera_ios,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onTakePicture(BuildContext context, Size size) async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    try {
      final xFile = await controller?.takePicture();
      await controller?.pausePreview();
      if (xFile != null) {
        notiBtnTake.value = false;
        if (mounted) {
          final result = await _DialogAsk(context, widget.language).show(xFile.path, size);

          if (result is String && mounted) {
            Navigator.pop(context, result);
          }
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
    }
    await controller?.resumePreview();
    notiBtnTake.value = false;
  }

  void onSwitchCamera() {
    var description = _cameras[0];
    if (_cameras.length > 1 && isBackCamera) {
      description = _cameras[1];
      isBackCamera = false;
    } else {
      isBackCamera = true;
    }
    controller?.setDescription(description);
    controller?.setZoomLevel(1);
  }

  void onShowRecentImage(BuildContext context, Size size) async {
    if (notiBtnTake.value) return;
    _SelectImage().show(
      context,
      widget.language,
      scaffoldState.currentState!,
    );
  }

  Future<void> initCamera([CameraDescription? description]) async {
    _cameras = await availableCameras();
    await PhotoManager.clearFileCache();
    await getPhoto();
    pathSaveFile = (await getApplicationDocumentsDirectory()).path;
    return;
  }

  Future<void> getPhoto() async {
    final resultPermission = await getPermissionImage();

    if (!resultPermission) return;

    await for (final item in _SelectImage().getListPhoto()) {
      notiPathRecent.value = item.path;
    }
  }

  Future<bool> getPermissionImage() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(); // the method can use optional param `permission`.
    if (ps.isAuth) {
      return true;
    } else if (ps.hasAccess) {
      return true;
    } else if (ps == PermissionState.denied) {
      return true;
    }
    // Limited(iOS) or Rejected, use `==` for more precise judgements.
    // You can call `PhotoManager.openSetting()` to open settings for further steps.
    return false;
  }

  void onFocusCamera(Size size, TapDownDetails details) async {
    final dx = details.localPosition.dx / size.width;
    final dy = details.localPosition.dy / size.height;
    await controller?.setFocusMode(FocusMode.locked);
    controller?.setFocusPoint(Offset(dx, dy));
  }

  void setFlashMode() async {
    if (notiFlashMode.value == FlashMode.off) {
      notiFlashMode.value = FlashMode.auto;
    } else if (notiFlashMode.value == FlashMode.auto) {
      notiFlashMode.value = FlashMode.always;
    } else {
      notiFlashMode.value = FlashMode.off;
    }
    await controller?.setFlashMode(notiFlashMode.value);
  }
}
