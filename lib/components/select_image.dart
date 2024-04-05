part of '../camera_custom.dart';

class SelectImage {
  final scrollController = ScrollController();
  final streamList = StreamController<List<File>>();
  final lock = Lock();
  List<File> listPhoto = [];

  var isLimitPhoto = false;

  _SelectImage([int limit = 30]) {
    scrollController.addListener(() async {
      if (listPhoto.length ~/ limit == 0) return;

      final isGetMore = scrollController.position.maxScrollExtent - scrollController.position.pixels <= 100;

      if (isGetMore && !isLimitPhoto) {
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

    if (lstPhoto.isEmpty) {
      isLimitPhoto = true;
      if (streamList.isClosed) return;
      streamList.sink.add(listPhoto);
      return;
    }

    for (final item in lstPhoto) {
      final file = await item.file;
      if (file != null) {
        yield file;
      }
    }
    //
    // ReceivePort receivePort = ReceivePort();
    // final token = RootIsolateToken.instance;
    //
    // final isolate = await Isolate.spawn(
    //   (message) async {
    //     BackgroundIsolateBinaryMessenger.ensureInitialized(message.token);
    //     SendPort sendPort = message.port;
    //     final lstFile = <File>[];
    //
    //     for (final item in message.lstPhoto) {
    //       final file = await item.file;
    //       if (file != null) {
    //         lstFile.add(file);
    //       }
    //     }
    //
    //     sendPort.send(lstFile);
    //   },
    //   (
    //     port: receivePort.sendPort,
    //     lstPhoto: lstPhoto,
    //     token: token!,
    //   ),
    // );
    //
    // for (final file in await receivePort.first) {
    //   yield file;
    // }
    //
    // isolate.kill(priority: Isolate.immediate);
  }

  Future show(
    BuildContext context,
    CameraLanguage language,
    ScaffoldState scaffoldState, {
    int limit = 30,
    bool hasConfirm = true,
  }) async {
    final size = MediaQuery.of(context).size;
    await PhotoManager.clearFileCache();

    final resultPermission = await _getPermissionImage();
    String? pathChoice;
    String? msg;

    if (!resultPermission) {
      msg = language.noLibraryAccess;
    }

    getListPhoto(page: 0, limit: limit).listen(
      (value) {
        if (streamList.isClosed) return;
        listPhoto.add(value);
        streamList.sink.add(listPhoto);
      },
    );

    await scaffoldState
        .showBottomSheet(
          (contextSheet) => Container(
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
                    builder: (contextStream, snapshot) {
                      if (snapshot.data!.isEmpty && isLimitPhoto) {
                        return Center(
                          child: Text(msg ?? language.noPhotoOnGallery),
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
                        addAutomaticKeepAlives: true,
                        children: List.generate(
                          snapshot.data!.length +
                              (isLimitPhoto
                                  ? 0
                                  : snapshot.data!.isEmpty
                                      ? 18
                                      : 6),
                          (index) {
                            if (index >= snapshot.data!.length) {
                              return const Placeholder().shimmer(size, true);
                            }
                            final item = snapshot.data![index];

                            return InkWell(
                              onTap: () async {
                                pathChoice = item.path;
                                Navigator.pop(contextStream);
                                if (!hasConfirm) return;
                                await Future.delayed(const Duration(milliseconds: 300));
                                if (context.mounted) {
                                  final result = await _DialogAsk(context, language).show(item.path, size);
                                  if (result is String && context.mounted) {
                                    Navigator.pop(context, result);
                                  }
                                }
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.file(
                                  snapshot.data![index],
                                  fit: BoxFit.cover,
                                  repeat: ImageRepeat.noRepeat,
                                  scale: .1,
                                  filterQuality: FilterQuality.low,
                                  cacheHeight: (size.width * .9).toInt(),
                                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                    if (frame == null) {
                                      return const Placeholder().shimmer(size, true);
                                    }
                                    return child;
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

    return pathChoice;
  }

  Future<bool> _getPermissionImage() async {
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
}
