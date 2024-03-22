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
  final String noQrInImage;
  final String toMuchQr;

  CameraLanguage({
    this.contentLoadCamera = 'Camera is initializing',
    this.styleLoadCamera,
    this.noPhotoOnGallery = 'There are no photos in the gallery',
    this.styleNoPhotoOnGallery,
    this.confirmChoice = 'Confirm selection of this photo?',
    this.styleConfirmChoice,
    this.confirm = 'Agree',
    this.cancel = 'Cancel',
    this.scanQR = 'Insert the QR code into the frame',
    this.choiceImageFromGallery = 'Select the photo',
    this.noQrInImage = 'No QR code seen in the photo',
    this.toMuchQr = 'There are too many QR codes in the screen',
  });
}
