part of '../camera_custom.dart';

extension _ExWidget on Widget {
  Widget shimmer(
    Size size,
    bool loading, {
    double? maxWidth,
    double? maxHeight,
    double? radius,
  }) {
    if (loading) {
      return _ShimmerLayout.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          width: maxWidth ?? max(size.width * .3, Random().nextDouble() * size.width),
          height: maxHeight,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(radius ?? 10)),
          child: const Padding(padding: EdgeInsets.symmetric(horizontal: 5)),
        ),
      );
    }

    return this;
  }
}


extension MLKitUtils on AnalysisImage {

  InputImage toInputImage() {
    return when(
      nv21: (image) {
        return InputImage.fromBytes(
          bytes: image.bytes,
          metadata: InputImageMetadata(
            rotation: inputImageRotation,
            format: InputImageFormat.nv21,
            size: image.size,
            bytesPerRow: image.planes.first.bytesPerRow,
          ),
        );
      },
      bgra8888: (image) {
        final inputImageData = InputImageMetadata(
          size: size,
          rotation: inputImageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        );

        return InputImage.fromBytes(
          bytes: image.bytes,
          metadata: inputImageData,
        );
      },
    )!;
  }

  InputImageRotation get inputImageRotation => InputImageRotation.values.byName(rotation.name);

  InputImageFormat get inputImageFormat {
    switch (format) {
      case InputAnalysisImageFormat.bgra8888:
        return InputImageFormat.bgra8888;
      case InputAnalysisImageFormat.nv21:
        return InputImageFormat.nv21;
      default:
        return InputImageFormat.yuv420;
    }
  }
}
