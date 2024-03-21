library camera_normal;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:camera_normal/components/language.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:synchronized/synchronized.dart';

part 'components/camera_view.dart';
part 'components/extension.dart';
part 'components/shimmer.dart';
part 'src/camera_normal.dart';
part 'src/camera_qr.dart';
