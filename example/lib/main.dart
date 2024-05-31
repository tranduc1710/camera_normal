import 'dart:io';

import 'package:camera_normal/camera_custom.dart';
import 'package:camera_normal/components/language.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo Camera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: false,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final notiBtnTake = ValueNotifier<bool>(false);
  final content = ValueNotifier("");
  CameraController? cameraController;

  final sizeBtn = 55.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final heightFrameQR = 400.0 * size.aspectRatio;

    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(content.value),
            ),
            FilledButton(
              onPressed: () async {
                final result = await CameraNormal().show(context, const CameraLanguage());
                print(result);
              },
              child: const Text('Camera normal'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await CameraQr().show(context);
                setState(() {
                  content.value = result ?? '';
                });
              },
              child: const Text('Camera QR'),
            ),
            //todo: take cic
            FilledButton(
              onPressed: () async {
                final path = await CameraTakeCIC(
                  onSetController: (p0) => cameraController = p0,
                  build: (context) => Stack(
                    children: [
                      Positioned(
                        top: size.height / 2 - heightFrameQR / 2 - 70,
                        left: size.width * .2,
                        right: size.width * .2,
                        child: const Text(
                          "Include citizen identification card in the frame",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(.95, -.92),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                      ),
                      Align(
                        alignment: const Alignment(0, .8),
                        child: GestureDetector(
                          onTap: () => onTakePicture(context, size),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white38,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            width: sizeBtn + 5,
                            height: sizeBtn + 5,
                            child: ValueListenableBuilder(
                              valueListenable: notiBtnTake,
                              builder: (BuildContext context, value, Widget? child) {
                                if (value) {
                                  return Center(
                                    child: SizedBox(
                                      width: sizeBtn - 10,
                                      height: sizeBtn - 10,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }
                                return Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.white,
                                  size: sizeBtn / 2,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).show(context);
                if (path is String && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Image.file(File(path)),
                    ),
                  );
                }
              },
              child: const Text(
                'Camera take CIC',
                textAlign: TextAlign.center,
              ),
            ),
            FilledButton(
              onPressed: () async {
                final path = await SelectImage().show(context, CameraLanguage());
                if (path is String && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      child: Image.file(File(path)),
                    ),
                  );
                }
              },
              child: const Text(
                'Show image',
                textAlign: TextAlign.center,
              ),
            ),
            // CameraCustom(
            //   cameraView: CameraView(),
            //   builder: (context, cameraView) {
            //     return Container(
            //       color: Colors.blue,
            //       width: 300,
            //       height: 500,
            //       child: Stack(
            //         children: [
            //           SizedBox(
            //             width: 250,
            //             height: 400,
            //             child: cameraView,
            //           ),
            //         ],
            //       ),
            //     );
            //   },
            // ),
          ],
        ),
      ),
    );
  }

  void onTakePicture(BuildContext context, Size size) async {
    if (notiBtnTake.value) return;
    notiBtnTake.value = true;
    try {
      final xFile = await cameraController?.takePicture();
      await cameraController?.pausePreview();
      if (xFile != null) {
        final img = await image.decodeImageFile(xFile.path);
        if (img != null) {
          final heightImg = img.height;
          final widthImg = img.width;
          final heightFrame = widthImg * .55;
          final widthImage = (widthImg * .9).toInt();
          final heightImage = (widthImg * .55).toInt();

          final imageCrop = image.copyCrop(
            img,
            x: 0,
            y: (heightImg / 2 - heightFrame / 2).toInt(),
            width: widthImage,
            height: heightImage,
          );
          await File(xFile.path).writeAsBytes(image.encodePng(imageCrop));

          notiBtnTake.value = false;
          if (context.mounted) {
            final result = await DialogConfirmImage(context).show(xFile.path, size);

            if (result is String && context.mounted) {
              Navigator.pop(context, result);
            }
          }
        }
      }
    } catch (e, s) {
      print(e);
      print(s);
    }
    await cameraController?.resumePreview();
    notiBtnTake.value = false;
  }
}
