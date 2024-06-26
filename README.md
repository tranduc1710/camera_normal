# camera_normal

<?code-excerpt path-base="example/lib"?>

A Flutter plugin for iOS, Android allowing access to the device cameras.

|                | Android | iOS       |
|----------------|---------|-----------|
| **Support**    | SDK 21+ | iOS 12.0+ |


<p align="center" width="100%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/Screenshot_1711098864.png" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/Screenshot_1711098871.png" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/Screenshot_1711098909.png" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/Screenshot_1711098940.png" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/Screenshot_1711098955.png" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/2024-03-26 18.24.43.jpg" width="20%">
  <img src="https://github.com/tranduc1710/save_file/blob/master/2024-03-26 18.24.49.jpg" width="20%">
</p>

### iOS

Add two rows to the `ios/Runner/Info.plist`:

* one with the key `Privacy - Camera Usage Description` and a usage description.
* and one with the key `Privacy - Microphone Usage Description` and a usage description.
* and one with the key `Privacy - Photo Library Usage Description` and a usage description.

If editing `Info.plist` as text, add:

```xml
<key>NSCameraUsageDescription</key>
<string>your usage description here</string>
<key>NSMicrophoneUsageDescription</key>
<string>your usage description here</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>In order to access your photo library</string>
```

- Minimum iOS Deployment Target: 12.0
- Xcode 13.2.1 or newer
- Swift 5
- ML Kit does not support 32-bit architectures (i386 and armv7). ML Kit does support 64-bit architectures (x86_64 and arm64). Check this [list](https://developer.apple.com/support/required-device-capabilities/) to see if your device has the required device capabilities. More info [here](https://developers.google.com/ml-kit/migration/ios).

Since ML Kit does not support 32-bit architectures (i386 and armv7), you need to exclude armv7 architectures in Xcode in order to run `flutter build ios` or `flutter build ipa`. More info [here](https://developers.google.com/ml-kit/migration/ios).

Go to Project > Runner > Building Settings > Excluded Architectures > Any SDK > armv7

<p align="center" width="100%">
  <img src="https://github.com/flutter-ml/google_ml_kit_flutter/blob/master/resources/build_settings_01.png">
</p>

Your Podfile should look like this:

```ruby
platform :ios, '12.0'  # or newer version

...

# add this line:
$iOSVersion = '12.0'  # or newer version

post_install do |installer|
  # add these lines:
  installer.pods_project.build_configurations.each do |config|
    config.build_settings["EXCLUDED_ARCHS[sdk=*]"] = "armv7"
    config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
  end
  
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # add these lines:
    target.build_configurations.each do |config|
      if Gem::Version.new($iOSVersion) > Gem::Version.new(config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'])
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = $iOSVersion
      end
    end
    
  end
end
```

Notice that the minimum `IPHONEOS_DEPLOYMENT_TARGET` is 12.0, you can set it to something newer but not older.

### Android
Change the minimum Android sdk version to 21 (or higher) in your `android/app/build.gradle` file.

```groovy
minSdkVersion 21
```

_If you're not setting your `compileSdkVersion` or `targetSdkVersion` to 29,
you can skip this section._

On Android 10, **Scoped Storage** was introduced,
which causes the origin resource file not directly
inaccessible through it file path.

If your `compileSdkVersion` or `targetSdkVersion` is `29`,
you can consider adding `android:requestLegacyExternalStorage="true"`
to your `AndroidManifest.xml` in order to obtain resources:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.fluttercandies.photo_manager_example">

    <uses-permission android:name="android.permission.FLASHLIGHT"/>

    <uses-feature
            android:name="android.hardware.camera"
            android:required="true"/>

    <application
            android:label="example"
            android:name="${applicationName}"
            android:requestLegacyExternalStorage="true"
            android:icon="@mipmap/ic_launcher">
</manifest>
```

##### Kotlin, Gradle, AGP

We ship this plugin with **Kotlin `1.7.22`**.
If your projects use a lower version of Kotlin/Gradle/AGP,
please upgrade them to a newer version.

More specifically:

- Upgrade your Gradle version (`gradle-wrapper.properties`)
  to `7.5.1` or the latest version.
- Upgrade your Kotlin version (`ext.kotlin_version`)
  to `1.7.22` or the latest version.
- Upgrade your AGP version (`com.android.tools.build:gradle`)
  to `7.2.2` or the latest version.

### Example

```dart
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
            CameraCustom(
              cameraView: CameraView(),
              builder: (context, cameraView) {
                return Container(
                  color: Colors.blue,
                  width: 300,
                  height: 500,
                  child: Stack(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 400,
                        child: cameraView,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

```