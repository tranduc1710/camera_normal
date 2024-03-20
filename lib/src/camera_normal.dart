part of '../camera_custom.dart';

class CameraNormal extends StatefulWidget {
  const CameraNormal({super.key});

  Future<String?> show(BuildContext context) async {
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

class _CameraNormalState extends State<CameraNormal> with AutomaticKeepAliveClientMixin {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  final scaffoldState = GlobalKey<ScaffoldState>();
  final streamListPhoto = StreamController<List<File>>();

  final notiBtnTake = ValueNotifier<bool>(false);
  final notiPathRecent = ValueNotifier('');

  var flashMode = FlashMode.auto;
  var isBackCamera = true;
  var contentError = '';
  var pathSaveFile = '';
  var isLimitPhoto = false;
  final limit = 30;

  List<File> listPhoto = [];

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
    notiBtnTake.dispose();
    streamListPhoto.close();
    PhotoManager.clearFileCache();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return FutureBuilder(
      future: initCamera(size),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoadingCamera();
        }
        if (contentError.isNotEmpty) {
          return buildError();
        }
        return Scaffold(
          key: scaffoldState,
          backgroundColor: Colors.black,
          body: Column(
            children: [
              buildTop(size, padding),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      width: size.width,
                      top: 0,
                      child: CameraPreview(
                        controller!,
                        child: GestureDetector(
                          onTapDown: (details) => onFocusCamera(size, details),
                        ),
                      ),
                    ),
                    Positioned(
                      width: size.width,
                      bottom: 0,
                      child: buildBottom(size, padding),
                    ),
                  ],
                ),
              ),
            ],
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

  Scaffold buildLoadingCamera() {
    return const Scaffold(
      body: Center(
        child: Text(
          'Camera đang khởi chạy',
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  }

  Container buildTop(Size size, EdgeInsets padding) {
    return Container(
      width: size.width,
      padding: EdgeInsets.only(top: padding.top),
      color: Colors.black54,
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
            icon: const Icon(
              Icons.flash_auto,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Container buildBottom(Size size, EdgeInsets padding) {
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
              onTap: () => onShowRecentImage(size),
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
                onTap: () => onTakePicture(size),
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

  void onTakePicture(Size size) async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    try {
      final xFile = await controller?.takePicture();
      await controller?.pausePreview();
      if (xFile != null) {
        // final path = pathSaveFile + xFile.path.split('/').last;
        // await xFile.saveTo(path);
        // notiPathRecent.value = xFile.path;
        notiBtnTake.value = false;
        if (mounted) {
          final result = await dialogAskPhoto(xFile.path, size);

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

  void onShowRecentImage(Size size) async {
    if (notiBtnTake.value) return;

    final scrollController = ScrollController();
    final streamList = StreamController<List<File>>();
    final lock = Lock();

    scrollController.addListener(() async {
      final isGetMore = scrollController.position.maxScrollExtent - scrollController.position.pixels <= 100;

      if (isGetMore) {
        if (isLimitPhoto) return;
        lock.synchronized(() async {
          await getListPhoto(
            page: listPhoto.length ~/ limit,
            limit: limit,
          ).listen(
            (value) {
              if (streamList.isClosed) return;
              listPhoto.add(value);
              streamList.sink.add(listPhoto);
            },
          ).asFuture();
        });
      }
    });

    await scaffoldState.currentState
        ?.showBottomSheet(
          (context) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    height: 4,
                    width: size.width * .2,
                    margin: const EdgeInsets.only(top: 10, bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: StreamBuilder(
                    stream: streamList.stream,
                    initialData: listPhoto,
                    builder: (context, snapshot) {
                      print(snapshot.data?.length);
                      if (snapshot.data!.isEmpty && isLimitPhoto) {
                        return const Center(
                          child: Text('Không có ảnh nào trong thư viện'),
                        );
                      }

                      return GridView.count(
                        crossAxisCount: 3,
                        mainAxisSpacing: 3,
                        crossAxisSpacing: 3,
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          bottom: 10,
                          left: 15,
                          right: 15,
                        ),
                        children: List.generate(
                          snapshot.data!.length +
                              (isLimitPhoto
                                  ? 0
                                  : snapshot.data!.isEmpty
                                      ? 18
                                      : 9),
                          (index) {
                            if (index >= snapshot.data!.length) {
                              return const Placeholder().shimmer(
                                size,
                                true,
                              );
                            }

                            return InkWell(
                              onTap: () async {
                                Navigator.pop(context);
                                await Future.delayed(const Duration(milliseconds: 300));
                                final result = await dialogAskPhoto(snapshot.data![index].path, size);
                                if (result is String && mounted) {
                                  Navigator.pop(this.context, result);
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(
                                  snapshot.data![index],
                                  fit: BoxFit.cover,
                                  repeat: ImageRepeat.noRepeat,
                                  scale: .1,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: size.height * .8,
          ),
          backgroundColor: Colors.transparent,
          enableDrag: true,
        )
        .closed;

    scrollController.dispose();
    streamList.close();
  }

  Future<void> initCamera(Size size, [CameraDescription? description]) async {
    if (controller?.value.isInitialized ?? false) return;
    _cameras = await availableCameras();
    await PhotoManager.clearFileCache();
    await getPhoto();
    pathSaveFile = (await getApplicationDocumentsDirectory()).path;
    controller = CameraController(
      description ?? _cameras[0],
      ResolutionPreset.ultraHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller?.initialize();
    controller?.setDescription(description ?? _cameras[0]);
    controller?.setFlashMode(flashMode);

    getListPhoto(page: 0, limit: limit).listen((value) {
      if (streamListPhoto.isClosed) return;
      listPhoto.add(value);
      streamListPhoto.sink.add(listPhoto);
    });
    return;
  }

  Future<void> getPhoto() async {
    final resultPermission = await getPermissionImage();

    if (!resultPermission) return;

    await for (final item in getListPhoto()) {
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

  Stream<File> getListPhoto({int page = 0, int limit = 1}) async* {
    final lstPhoto = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: limit,
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [
          const OrderOption(
            asc: false,
            type: OrderOptionType.createDate,
          ),
        ],
      ),
    );

    if (lstPhoto.isEmpty) isLimitPhoto = true;

    ReceivePort receivePort = ReceivePort();
    final token = RootIsolateToken.instance;

    final isolate = await Isolate.spawn(
      (message) async {
        BackgroundIsolateBinaryMessenger.ensureInitialized(message.token);
        SendPort sendPort = message.port;
        final lstFile = <File>[];

        for (final item in message.lstPhoto) {
          final file = await item.file;
          if (file != null) {
            lstFile.add(file);
          }
        }

        sendPort.send(lstFile);
      },
      (
        port: receivePort.sendPort,
        lstPhoto: lstPhoto,
        token: token!,
      ),
    );

    for (final file in await receivePort.first) {
      yield file;
    }

    isolate.kill(priority: Isolate.immediate);
  }

  @override
  bool get wantKeepAlive => true;

  Future dialogAskPhoto(String pathFile, Size size) async {
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.only(
          bottom: size.height * .085,
          left: size.width * .05,
          right: size.width * .05,
        ),
        child: Material(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                width: double.infinity,
                // decoration: BoxDecoration(
                //   border: Border.all(
                //     width: 1,
                //     color: Colors.grey.withOpacity(.2),
                //   ),
                //   borderRadius: BorderRadius.circular(10),
                // ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: InteractiveViewer(
                    child: Image.file(
                      File(pathFile),
                      height: size.height * .4,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 10),
                child: Text(
                  'Xác nhận chọn ảnh này?',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 15),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: FilledButton(
                        style: const ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(Colors.white),
                          foregroundColor: MaterialStatePropertyAll(Colors.grey),
                          shape: MaterialStatePropertyAll(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.all(Radius.circular(50)),
                              side: BorderSide(width: 1, color: Colors.grey),
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Huỷ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(pathFile),
                        child: const Text(
                          'Đồng ý',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onFocusCamera(Size size, TapDownDetails details) async {
    final dx = details.localPosition.dx / size.width;
    final dy = details.localPosition.dy / size.height;
    await controller?.setFocusMode(FocusMode.locked);
    controller?.setFocusPoint(Offset(dx, dy));
  }

  void setFlashMode() {
    if (flashMode == FlashMode.off) {
      flashMode = FlashMode.auto;
    } else if (flashMode == FlashMode.auto) {
      flashMode = FlashMode.always;
    } else {
      flashMode = FlashMode.off;
    }
    controller?.setFlashMode(flashMode);
  }
}
