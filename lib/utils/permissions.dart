import 'package:permission_handler/permission_handler.dart';

Future<bool> handleCameraAndMicPermissions() async {
  var cameraStatus = await Permission.camera.request();
  if (!cameraStatus.isGranted) {
    return false;
  }

  var micStatus = await Permission.microphone.request();
  if(!micStatus.isGranted) {
    return false;
  }
  return true;
}