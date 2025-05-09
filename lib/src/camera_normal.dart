part of '../camera_custom.dart';

class CameraNormal extends StatefulWidget {
  final bool showChoiceImage;
  CameraLanguage language = const CameraLanguage();

  CameraNormal({super.key, this.showChoiceImage = true});

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
  PhotoCameraState? photoCameraState;
  late CameraState cameraState;

  final scaffoldState = GlobalKey<ScaffoldState>();

  final notiBtnTake = ValueNotifier<bool>(false);
  final notiPathRecent = ValueNotifier('');

  var notiFlashMode = ValueNotifier(FlashMode.auto);
  var isBackCamera = true;
  var contentError = '';
  var pathSaveFile = '';

  List<File> listPhoto = [];
  final sizeBtn = 55.0;

  @override
  void dispose() async {
    super.dispose();
    notiBtnTake.dispose();
    notiPathRecent.dispose();
    notiFlashMode.dispose();
    await PhotoManager.clearFileCache();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      key: scaffoldState,
      backgroundColor: Colors.black,
      body: CameraAwesomeBuilder.awesome(
        previewFit: CameraPreviewFit.contain,
        saveConfig: SaveConfig.photo(
          pathBuilder: (sensors)async {
            final Directory extDir = await getTemporaryDirectory();
            final testDir = await Directory(
              '${extDir.path}/cameranormal',
            ).create(recursive: true);
            if (sensors.length == 1) {
              final String filePath =
                  '${testDir.path}/image.jpg';
              return SingleCaptureRequest(filePath, sensors.first);
            }
            // Separate pictures taken with front and back camera
            return MultipleCaptureRequest(
              {
                for (final sensor in sensors)
                  sensor:
                  '${testDir.path}/${sensor.position == SensorPosition.front ? 'front_' : "back_"}${DateTime.now().millisecondsSinceEpoch}.jpg',
              },
            );
          },
        ),
        onMediaCaptureEvent: (event) {
          switch ((event.status, event.isPicture, event.isVideo)) {
            case (MediaCaptureStatus.capturing, true, false):
              debugPrint('Capturing picture...');
            case (MediaCaptureStatus.success, true, false):
              event.captureRequest.when(
                single: (single) {
                  debugPrint('Picture saved: ${single.file?.path}');
                  onTakePicture(context, size, event);
                },
              );
            default:
              debugPrint('Unknown event: $event');
          }
        },
        // onMediaCaptureEvent: (mediaCapture) => onTakePicture(context, size, mediaCapture),
        topActionsBuilder: (state) => AwesomeTopActions(
          state: state,
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
            // AwesomeFlashButton(
            //   state: state,
            //   iconBuilder: (flashMode) {
            //     switch (flashMode) {
            //       case FlashMode.none:
            //         return const Icon(Icons.flash_off);
            //       case FlashMode.on:
            //         return const Icon(Icons.flash_on);
            //       case FlashMode.auto:
            //         return const Icon(Icons.flash_auto);
            //       case FlashMode.always:
            //         return const Icon(Icons.flashlight_on);
            //     }
            //   },
            //   onFlashTap: (sensorConfig, flashMode) {
            //     setFlashMode(sensorConfig, flashMode);
            //
            //     sensorConfig.setFlashMode(flashMode);
            //   },
            // ),
          ],
        ),
        bottomActionsBuilder: (state) => AwesomeBottomActions(
          state: state,
          left: GestureDetector(
            onTap: () => onShowRecentImage(context, size),
            child: Center(
              child: Container(
                width: sizeBtn,
                height: sizeBtn,
                decoration: widget.showChoiceImage
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey,
                        ),
                      )
                    : null,
                child: widget.showChoiceImage
                    ? ClipRRect(
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
                      )
                    : const SizedBox(),
              ),
            ),
          ),
          right: AwesomeCameraSwitchButton(
            state: state,
            scale: 1.0,
            onSwitchTap: (state) {
              state.switchCameraSensor(
                aspectRatio: state.sensorConfig.aspectRatio,
              );
            },
          ),
        ),

      ),
    );
  }

  Container buildTop(BuildContext context, Size size, EdgeInsets padding) {
    return Container(
      width: size.width,
      padding: EdgeInsets.only(top: padding.top),
      color: Colors.black26,
      child: Row(
        children: [],
      ),
    );
  }

  Container buildBottom(BuildContext context, Size size, EdgeInsets padding) {
    return Container(
      color: Colors.black26,
      width: size.width,
      padding: EdgeInsets.only(
        bottom: padding.bottom + 30,
        top: 15,
      ),
      child: Row(
        children: [
          // Expanded(
          //   child: Center(
          //     child: GestureDetector(
          //       onTap: onSwitchCamera,
          //       child: const Padding(
          //         padding: EdgeInsets.all(8.0),
          //         child: Icon(
          //           Icons.flip_camera_ios,
          //           color: Colors.white,
          //           size: 30,
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  void onTakePicture(BuildContext context, Size size, MediaCapture mediaCapture) async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    // try {
    print("hello:  ${mediaCapture.captureRequest.path}");
    if (mediaCapture.captureRequest.path != null) {
      notiBtnTake.value = false;
      if (mounted) {
        DialogConfirmImage(context, widget.language).show(mediaCapture.captureRequest.path!, size).then(
          (result) {
            if (result is String && mounted) {
              Navigator.pop(context, result);
            }
          },
        );
      }
    }
    // } catch (e, s) {
    //   print(e);
    //   print(s);
    // }
    notiBtnTake.value = false;
  }

  //
  // void onSwitchCamera() {
  //   var description = _cameras[0];
  //   if (_cameras.length > 1 && isBackCamera) {
  //     description = _cameras[1];
  //     isBackCamera = false;
  //   } else {
  //     isBackCamera = true;
  //   }
  //   controller?.setDescription(description);
  //   controller?.setZoomLevel(1);
  // }

  void onShowRecentImage(BuildContext context, Size size) async {
    if (notiBtnTake.value) return;
    final imageSelect = await SelectImage().show(
      context,
      widget.language,
    );
    if (imageSelect is String && context.mounted) {
      Navigator.pop(context, imageSelect);
    }
  }

  // Future<void> initCamera([CameraDescription? description]) async {
  //   _cameras = await availableCameras();
  //   if (widget.showChoiceImage) {
  //     await PhotoManager.clearFileCache();
  //     await getPhoto();
  //   }
  //   pathSaveFile = (await getApplicationDocumentsDirectory()).path;
  //   return;
  // }

  Future<void> getPhoto() async {
    final resultPermission = await getPermissionImage();

    if (!resultPermission) return;

    await for (final item in SelectImage().getListPhoto()) {
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

  // void onFocusCamera(Size size, TapDownDetails details) async {
  //   final dx = details.localPosition.dx / size.width;
  //   final dy = details.localPosition.dy / size.height;
  //   await controller?.setFocusMode(FocusMode.locked);
  //   controller?.setFocusPoint(Offset(dx, dy));
  // }
  //
  void setFlashMode(SensorConfig sensorConfig, FlashMode flashMode) async {
    notiFlashMode.value = flashMode;
  }
}
