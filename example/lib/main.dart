import 'dart:io';

import 'package:camera_normal/camera_custom.dart';
import 'package:camera_normal/components/language.dart';
import 'package:flutter/material.dart';

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
  String content = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(content),
            ),
            FilledButton(
              onPressed: () async {
                final result = await CameraNormal().show(context, CameraLanguage());
                setState(() {
                  content = result ?? '';
                });
              },
              child: const Text('Camera normal'),
            ),
            FilledButton(
              onPressed: () async {
                final result = await CameraQr().show(context);
                setState(() {
                  content = result ?? '';
                });
              },
              child: const Text('Camera QR'),
            ),
            FilledButton(
              onPressed: () async {
                final path = await CameraTakeCIC().show(context);
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
}
