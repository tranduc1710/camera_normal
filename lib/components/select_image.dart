part of '../camera_custom.dart';

class SelectImage {
  final streamList = StreamController<List<File>>();
  List<File> listPhoto = [];
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

  Stream<File> getListPhoto({int page = 0, int limit = 1}) async* {
    final lstPhoto = await (albumSelected?.getAssetListPaged(
          page: page,
          size: limit,
        ) ??
        PhotoManager.getAssetListPaged(
          page: page,
          pageCount: limit,
          filterOption: filter,
        ));

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
    final selected = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (selected == null) return;

    if (hasConfirm && contextParent.mounted) {
      final result = await DialogConfirmImage(contextParent, language).show(selected.path, MediaQuery.of(contextParent).size);
      return result;
    }

    return selected.path;
  }
}
