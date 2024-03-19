import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CameraNormal extends StatefulWidget {
  const CameraNormal({super.key});

  @override
  _CameraNormalState createState() => _CameraNormalState();
}

class _CameraNormalState extends State<CameraNormal> with WidgetsBindingObserver {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  var lstPathsPhoto = ValueNotifier<List<AssetEntity>>([]);
  final scaffoldState = GlobalKey<ScaffoldState>();

  final notiBtnTake = ValueNotifier<bool>(false);
  final notiPathRecent = ValueNotifier('');

  var isBackCamera = true;
  var contentError = '';
  final limitPhoto = 40;
  var page = 0;

  @override
  void initState() {
    super.initState();
    getPhoto();
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
    notiBtnTake.dispose();
    PhotoManager.clearFileCache();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      intCamera(cameraController.description);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return FutureBuilder(
      future: intCamera(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return buildLoadingCamera();
        }
        if (contentError.isNotEmpty) {
          return buildError();
        }
        return Scaffold(
          key: scaffoldState,
          body: Stack(
            children: [
              Positioned(
                height: size.height,
                width: size.width,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: CameraPreview(
                      controller!,
                    ),
                  ),
                ),
              ),
              Positioned(
                width: size.width,
                top: padding.top,
                child: buildTop(size, padding),
              ),
              Positioned(
                width: size.width,
                bottom: padding.bottom,
                child: buildBottom(size, padding),
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
      color: Colors.black26,
      padding: EdgeInsets.only(
        top: padding.top,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: Navigator.of(context).pop,
            icon: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(
                Icons.arrow_back_ios_new_outlined,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container buildBottom(Size size, EdgeInsets padding) {
    return Container(
      color: Colors.black26,
      width: size.width,
      padding: EdgeInsets.only(
        bottom: padding.bottom + 30,
        top: 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: IconButton(
              onPressed: () => onShowRecentImage(size),
              icon: Container(
                width: 70,
                height: 55,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    width: 1,
                    color: Colors.grey,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ValueListenableBuilder(
                    valueListenable: notiPathRecent,
                    builder: (context, value, child) {
                      if (value.isEmpty) return const Icon(Icons.image_outlined);
                      return Image.file(
                        File(value),
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: onTakePicture,
              padding: const EdgeInsets.all(5),
              highlightColor: Colors.transparent,
              icon: Container(
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: ValueListenableBuilder(
                  valueListenable: notiBtnTake,
                  builder: (BuildContext context, value, Widget? child) {
                    if (value) {
                      return const SizedBox(
                        width: 53,
                        height: 53,
                        child: CircularProgressIndicator(),
                      );
                    }
                    return const Padding(
                      padding: EdgeInsets.all(15.0),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 30,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: IconButton(
              onPressed: onSwitchCamera,
              icon: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.flip_camera_ios,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void onTakePicture() async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    try {
      final xFile = await controller?.takePicture();
      if (xFile != null) {
        notiPathRecent.value = xFile.path;
        lstPathsPhoto.value = await PhotoManager.getAssetListPaged(
          page: page,
          pageCount: limitPhoto,
          type: RequestType.image,
        );
      }
    } catch (e, s) {
      print(e);
      print(s);
    }
    notiBtnTake.value = false;
  }

  void onSwitchCamera() async {
    var description = _cameras[0];
    if (_cameras.length > 1 && !isBackCamera) {
      description = _cameras[1];
      isBackCamera = true;
    } else {
      isBackCamera = false;
    }
    controller?.setDescription(description);
  }

  void onShowRecentImage(Size size) async {
    final scrollController = ScrollController();
    scrollController.addListener(() async {
      if (scrollController.position.maxScrollExtent / scrollController.position.pixels <= .3) {
        page++;
        final listGet = await PhotoManager.getAssetListPaged(
          page: page,
          pageCount: limitPhoto,
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
        lstPathsPhoto.value.addAll(listGet);
      }
    });

    await scaffoldState.currentState
        ?.showBottomSheet(
          (context) => Column(
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: size.width * .2,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder(
                    valueListenable: lstPathsPhoto,
                    builder: (context, list, child) {
                      return GridView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          bottom: 10,
                          left: 15,
                          right: 15,
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 3,
                          crossAxisSpacing: 3,
                        ),
                        children: List.generate(
                          list.length,
                          (index) => FutureBuilder(
                            future: list[index].file,
                            builder: (context, snapshot) {
                              if (snapshot.data == null) return const Placeholder();
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
          constraints: BoxConstraints(
            maxHeight: size.height * .8,
          ),
          enableDrag: true,
        )
        .closed;

    scrollController.dispose();
  }

  Future<void> intCamera([CameraDescription? description]) async {
    if (controller?.value.isInitialized ?? false) return;
    _cameras = await availableCameras();
    await PhotoManager.clearFileCache();
    controller = CameraController(
      description ?? _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller?.initialize();
    if (!mounted) {
      return;
    }
    return;
  }

  void getPhoto() async {
    final resultPermission = await getPermissionImage();

    if (!resultPermission) return;

    lstPathsPhoto.value = await PhotoManager.getAssetListPaged(
      page: page,
      pageCount: limitPhoto,
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
    final path = await lstPathsPhoto.value.firstOrNull?.file;
    notiPathRecent.value = path?.path ?? '';

    print(lstPathsPhoto.value.length);
  }

  Future<bool> getPermissionImage() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend(); // the method can use optional param `permission`.
    if (ps.isAuth) {
      return true;
    } else if (ps.hasAccess) {
      return true;
    }
    // Limited(iOS) or Rejected, use `==` for more precise judgements.
    // You can call `PhotoManager.openSetting()` to open settings for further steps.
    return false;
  }
}
