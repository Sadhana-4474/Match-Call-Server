import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../utils/permissions.dart';
import '../services/agora_service.dart';
import 'call_history_service.dart';

class AudioCallScreen extends StatefulWidget {
  final String channelName;
  final String receiverId;
  final String receiverName;
  final String token;

  const AudioCallScreen({
    super.key,
    required this.channelName,
    required this.receiverId,
    required this.receiverName,
    required this.token,
});

  @override
  State<AudioCallScreen> createState() => _AudioCallScreenState();
}

class _AudioCallScreenState extends State<AudioCallScreen> {
  int? _remoteUid;
  late DateTime _callStartTime;
  bool _isMicMuted = false;
  bool _isSpeakerOn = false;
  bool _joined = false;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _initCall();
  }

  Future<void> _initCall() async {
    final granted = await handleCameraAndMicPermissions();
    if (!granted) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final doc = await FirebaseFirestore.instance.collection('calls').doc(widget.channelName).get();
    final callData = doc.data();
    if(callData == null) {
      if(mounted) Navigator.maybePop(context);
      return;
    }

    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final isCaller = callData['callerId'] == myUid;
    final uid = isCaller ? callData['callerUid'] : callData['receiverUid'];
    final token = isCaller ? callData['callerToken'] : callData['receiverToken'];

    if (uid == null || token == null) {
      await Future.delayed(const Duration(seconds: 1));
    }

    if(_joined) return;
    await joinAgoraChannel(
      channelName: widget.channelName,
      token: token ?? widget.token,
      uid: uid ?? 0);
    _joined = true;
    await agoraEngine!.enableAudio();

    agoraEngine!.registerEventHandler(
      RtcEngineEventHandler(
        onUserJoined: (connection, remoteUid, elapsed) {
          setState(() => _remoteUid = remoteUid);
          },
        onUserOffline: (connection, uid, reason) async {
          setState(() => _remoteUid = null);
          },
      ),
    );
  }

  Future<void> _endCall() async {
    await CallHistoryService.endCall(
      channelName: widget.channelName,
      receiverId: widget.receiverId,
      receiverName: widget.receiverName,
      callType: "audio",
      startTime: _callStartTime,
    );
    await agoraEngine?.leaveChannel();

    if (mounted) Navigator.maybePop(context);
  }

  @override
  void dispose() {
    agoraEngine?.leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Call", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold )),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color(0xFFFFE0B2),
              Color(0xFFE1BEE7),
              Color(0xFFBBDEFB),
            ],
          ),
        ),
        child: Stack(
          children: [
            Center(
            child: _remoteUid != null ? Text("Connected to $_remoteUid", style: const TextStyle(fontSize: 20))
            : const Text("Waiting for remote user...", style: TextStyle(fontSize: 20)),
        ),

         Align(
          alignment: Alignment.bottomCenter,
           child: Padding(
               padding: const EdgeInsets.only(bottom: 30), child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
    ///Mute / Unmute Mic
           FloatingActionButton(
                   heroTag: "mic",
                   onPressed: () {
                              setState(() {_isMicMuted = !_isMicMuted;
                                  agoraEngine?.muteLocalAudioStream(_isMicMuted);
             });
         },
           backgroundColor: Colors.blue,
           child: Icon(_isMicMuted ? Icons.mic_off : Icons.mic, color: Colors.white,
            ),
        ),

    ///End Call
           FloatingActionButton(
                   heroTag: "end",
                   onPressed: _endCall,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, color: Colors.white),
    ),

    /// Speaker On/Off
           FloatingActionButton(
             heroTag: "speaker",
                onPressed: () {
                  setState(() {
                    _isSpeakerOn = !_isSpeakerOn;
                      agoraEngine?.setEnableSpeakerphone(_isSpeakerOn);
      });
    },
            backgroundColor: Colors.green,
            child: Icon(
              _isSpeakerOn ? Icons.volume_up : Icons.hearing,
              color: Colors.white,
             ),
          ),
       ],
      ),
    ),
  ),
 ],
),
      ),
    );
  }
}
