import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String appId = "af6296faa12444958370d9655380d002";
const String tokenBaseUrl = "https://match-call-server.onrender.com";

RtcEngine? agoraEngine;

///fetch token from backend
Future<String?> fetchToken(String channelName, int uid) async {
  try{
    final response = await http.get(
      Uri.parse('$tokenBaseUrl/generateToken?channelName=$channelName&uid=$uid'),
    );

    if(response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token =  data['token'] as String?;
      if(token == null || token.isEmpty) {
        print("Token missing in response: $data");
        return null;
      }
      return token;
    } else {
      print("Failed to fetch token: ${response.statusCode}, body: ${response.body}");
      return null;
    }
  } catch (e) {
    print("Error fetching token: $e");
    return null;
  }
}

///initialize agora engine
Future<void> initAgoraEngine() async {
  if(agoraEngine != null) return;
  agoraEngine = createAgoraRtcEngine();
  await agoraEngine!.initialize(
    const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ),
  );
  print("Agora Engine initialized");
}

///join channel
Future<int?> joinAgoraChannel({
  required String channelName,
  required String token,
  required int uid,
}) async {
  await initAgoraEngine();

  await agoraEngine!.joinChannel(
    token: token,
    channelId: channelName,
    uid: uid,
    options: const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
    ),
  );
  print("Joined channel: $channelName with uid $uid");
  return uid;
}

/// Leave Agora channel
Future<void> leaveAgoraChannel() async {
  if (agoraEngine != null) {
    await agoraEngine!.leaveChannel();
    print("Left channel");
  }
}

/// Enable audio
Future<void> enableAudio() async {
  await agoraEngine?.enableAudio();
}

/// Enable video
Future<void> enableVideo() async {
  await agoraEngine?.enableVideo();
}

/// Mute/unmute local audio
Future<void> muteLocalAudio(bool mute) async {
  await agoraEngine?.muteLocalAudioStream(mute);
}

/// Mute/unmute local video
Future<void> muteLocalVideo(bool mute) async {
  await agoraEngine?.muteLocalVideoStream(mute);
}

/// Switch camera
Future<void> switchCamera() async {
  await agoraEngine?.switchCamera();
}

/// Enable/disable speakerphone
Future<void> setSpeakerphone(bool enable) async {
  await agoraEngine?.setEnableSpeakerphone(enable);
}