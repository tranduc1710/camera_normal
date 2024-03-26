library camera_normal;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:camera_normal/components/language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:synchronized/synchronized.dart';

part 'components/camera_view.dart';
part 'components/dialog/dialog_alert.dart';
part 'components/dialog/dialog_ask.dart';
part 'components/extension.dart';
part 'components/select_image.dart';
part 'components/shimmer.dart';
part 'src/camera_normal.dart';
part 'src/camera_qr.dart';
part 'src/camera_take_cccd.dart';
