import 'package:flutter/material.dart';

class CameraLanguage {
  final String contentLoadCamera;
  final TextStyle? styleLoadCamera;
  final String noPhotoOnGallery;
  final TextStyle? styleNoPhotoOnGallery;
  final String confirmChoice;
  final TextStyle? styleConfirmChoice;
  final String confirm;
  final String cancel;
  final String scanQR;
  final String choiceImageFromGallery;

  CameraLanguage({
    this.contentLoadCamera = 'Camera đang khởi chạy',
    this.styleLoadCamera,
    this.noPhotoOnGallery = 'Không có ảnh nào trong thư viện',
    this.styleNoPhotoOnGallery,
    this.confirmChoice = 'Xác nhận chọn ảnh này?',
    this.styleConfirmChoice,
    this.confirm = 'Đồng ý',
    this.cancel = 'Huỷ',
    this.scanQR = 'Đưa mã QR vào khung',
    this.choiceImageFromGallery = 'Tải ảnh lên',
  });
}
