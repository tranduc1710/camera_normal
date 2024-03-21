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
