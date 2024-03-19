import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:synchronized/synchronized.dart';

class CameraNormal extends StatefulWidget {
  const CameraNormal({super.key});

  @override
  _CameraNormalState createState() => _CameraNormalState();
}

class _CameraNormalState extends State<CameraNormal> with AutomaticKeepAliveClientMixin {
  late List<CameraDescription> _cameras;
  CameraController? controller;
  final scaffoldState = GlobalKey<ScaffoldState>();

  final notiBtnTake = ValueNotifier<bool>(false);
  final notiPathRecent = ValueNotifier('');

  var isBackCamera = true;
  var contentError = '';
  var pathSaveFile = '';

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
                    child: InkWell(
                      onTapUp: onFocusCamera,
                      child: CameraPreview(
                        controller!,
                      ),
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
        final fileSave = await File(pathSaveFile + xFile.path.split('/').last).writeAsBytes(
          await xFile.readAsBytes(),
          flush: true,
        );
        notiBtnTake.value = false;
        if (mounted) {
          final result = await showDialog(
            context: context,
            builder: (context) => dialogAskPhoto(fileSave),
          );

          if (result == true && mounted) {
            Navigator.pop(context, fileSave);
          }
        }
        return;
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
    var isLimitPhoto = false;
    const limit = 30;
    List<File> listPhoto = [];
    final streamListPhoto = StreamController<List<File>>();
    final lock = Lock();

    getListPhoto(page: 0, limit: limit).then((value) {
      listPhoto.addAll(value);
      streamListPhoto.sink.add(listPhoto);
    });

    scrollController.addListener(() async {
      final isGetMore = scrollController.position.maxScrollExtent - scrollController.position.pixels <= 100;

      if (isGetMore) {
        lock.synchronized(() async {
          if (isLimitPhoto) return;
          final listGet = await getListPhoto(page: listPhoto.length ~/ limit, limit: limit);
          if (streamListPhoto.isClosed) return;
          if (listGet.isEmpty) {
            isLimitPhoto = true;
            return;
          }
          listPhoto.addAll(listGet);
          streamListPhoto.sink.add(listPhoto);
        });
      }
    });

    await scaffoldState.currentState
        ?.showBottomSheet(
          (context) => Column(
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
                  stream: streamListPhoto.stream,
                  initialData: listPhoto,
                  builder: (context, snapshot) {
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
                          if (index >= snapshot.data!.length) return const Placeholder();

                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pop(context, snapshot.data![index]);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: FutureBuilder(
                                future: compute(
                                  (message) => Image.file(
                                    message,
                                    fit: BoxFit.cover,
                                    repeat: ImageRepeat.noRepeat,
                                    scale: .1,
                                  ),
                                  snapshot.data![index],
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.data == null) {
                                    return const SizedBox();
                                  }
                                  return snapshot.data!;
                                },
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
          constraints: BoxConstraints(
            maxHeight: size.height * .8,
          ),
          enableDrag: true,
        )
        .closed;

    scrollController.dispose();
    streamListPhoto.close();
  }

  Future<void> intCamera([CameraDescription? description]) async {
    if (controller?.value.isInitialized ?? false) return;
    _cameras = await availableCameras();
    await PhotoManager.clearFileCache();
    await getPhoto();
    pathSaveFile = (await getApplicationDocumentsDirectory()).path;
    controller = CameraController(
      description ?? _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller?.initialize();
    controller?.setDescription(description ?? _cameras[0]);

    return;
  }

  Future<void> getPhoto() async {
    final resultPermission = await getPermissionImage();

    if (!resultPermission) return;

    final lstPhoto = await getListPhoto();
    notiPathRecent.value = lstPhoto.firstOrNull?.path ?? '';
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

  Future<List<File>> getListPhoto({int page = 0, int limit = 1}) async {
    final lstFile = <File>[];

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

    final token = RootIsolateToken.instance;

    for (final item in lstPhoto) {
      final file = await compute(
        (token) async {
          BackgroundIsolateBinaryMessenger.ensureInitialized(token!);
          return await item.file;
        },
        token,
      );
      if (file != null) {
        lstFile.add(file);
      }
    }

    return lstFile;
  }

  @override
  bool get wantKeepAlive => true;

  Widget dialogAskPhoto(File fileSave) {
    return Dialog(
      child: Material(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Thông báo',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Xác nhận chọn ảnh này?',
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1,
                  color: Colors.grey.withOpacity(.2),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  fileSave,
                  height: 250,
                  fit: BoxFit.contain,
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
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Đồng ý',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
    );
  }

  void onFocusCamera(TapUpDetails details) {
    final dx = details.localPosition.dx / details.globalPosition.dx;
    final dy = details.localPosition.dy / details.globalPosition.dy;
    controller?.setFocusPoint(Offset(dx, dy));
  }
}
