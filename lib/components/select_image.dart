part of '../camera_custom.dart';

class SelectImage {
  final scrollController = ScrollController();
  final streamList = StreamController<List<File>>();
  final lock = Lock();
  List<File> listPhoto = [];
  ValueNotifier<String> albumName = ValueNotifier("All");
  AssetPathEntity? albumSelected;
  final PMFilter filter = FilterOptionGroup(
    orders: [
      const OrderOption(
        type: OrderOptionType.createDate,
        asc: false,
      ),
    ],
  );

  var isLimitPhoto = false;
  bool isOpenCamera = false;

  SelectImage([int limit = 30]) {
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
    if (albumSelected == null) return;
    final lstPhoto = await albumSelected!.getAssetListPaged(
      page: page,
      size: limit,
    );

    if (lstPhoto.isEmpty) {
      isLimitPhoto = true;
      if (streamList.isClosed) return;
      streamList.sink.add(listPhoto);
      return;
    }

    if (page == 0 && lstPhoto.length < limit) {
      isLimitPhoto = true;
    }

    for (final item in lstPhoto) {
      final file = await item.file;
      if (file != null) {
        yield file;
      }
    }
  }

  Future show(
    BuildContext contextParent,
    CameraLanguage language, {
    int limit = 30,
    bool hasConfirm = true,
  }) async {
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: filter,
    );
    albumSelected = albums.firstOrNull;
    albumName.value = albumSelected?.name ?? "All";
    final size = MediaQuery.of(contextParent).size;
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

    await showGeneralDialog(
      context: contextParent,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      barrierLabel: "showGeneralDialog",
      pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: size.height * .8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(.2),
                  blurRadius: 5,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 15, top: 20),
                            child: Text(
                              "Close",
                              style: TextStyle(color: Color(0xffF76F01), fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: PopupMenuButton<AssetPathEntity>(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          offset: const Offset(0, 0),
                          constraints: const BoxConstraints(maxHeight: 300),
                          position: PopupMenuPosition.under,
                          itemBuilder: (context) => [
                            ...List.generate(albums.length, (index) {
                              final item = albums[index];
                              return PopupMenuItem(
                                value: item,
                                child: SizedBox(width: 150, child: Text(item.name)),
                              );
                            }),
                          ],
                          onSelected: (AssetPathEntity value) {
                            albumSelected = value;
                            albumName.value = value.name;
                            listPhoto.clear();
                            streamList.sink.add(listPhoto);
                            isLimitPhoto = false;
                            getListPhoto(limit: 30).listen(
                              (value) {
                                if (streamList.isClosed) return;
                                listPhoto.add(value);
                                streamList.sink.add(listPhoto);
                              },
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            height: 45,
                            width: 200,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(width: 30),
                                Expanded(
                                  child: ValueListenableBuilder(
                                    valueListenable: albumName,
                                    builder: (context, name, child) => Container(
                                      constraints: const BoxConstraints(maxWidth: 150),
                                      child: Text(
                                        name,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_drop_down,
                                  size: 30,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () {
                            isOpenCamera = true;
                            Navigator.pop(context);
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(right: 15, top: 15),
                            child: Icon(
                              Icons.camera_alt,
                              size: 30,
                              color: Color(0xffF76F01),
                            ),
                          ),
                        ),
                      )
                    ],
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
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.file(
                                    snapshot.data![index],
                                    fit: BoxFit.cover,
                                    repeat: ImageRepeat.noRepeat,
                                    scale: .1,
                                    filterQuality: FilterQuality.low,
                                    cacheWidth: 200,
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
          ),
        );
      },
      transitionBuilder: (_, animation1, __, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: const Offset(0, 0),
          ).animate(animation1),
          child: child,
        );
      },
    );

    scrollController.dispose();
    streamList.close();

    if (isOpenCamera) {
      final valueImage = await CameraNormal().show(contextParent, const CameraLanguage());
      return valueImage;
    }

    if (hasConfirm && contextParent.mounted && pathChoice is String) {
      final result = await DialogConfirmImage(contextParent, language).show(pathChoice!, size);
      return result;
    }

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
    return false;
  }
}
