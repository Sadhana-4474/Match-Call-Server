import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../CallScreen/call_service.dart';
import '../CallScreen/AudioCallScreen.dart';
import '../CallScreen/VideoCallScreen.dart';
import '../main.dart';

class IncomingCallPage extends StatelessWidget {
  final Map<String, dynamic> callData;

  const IncomingCallPage({super.key, required this.callData});

  String get callId => callData['callId'] ?? callData['channelName'];
  String get callType => callData['callType'] ?? 'audio';
  String get callerId => callData['callerId'] ?? 'Unknown';
  String get receiverId => callData['receiverId'] ?? '';
  String get callerName => callData['callerName'] ?? callData['callerName'] ?? 'Unknown';

  Future<String> _fetchCallerName() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(callerId).get();
      return doc.data()?['name'] ?? callerName;
    } catch (e) {
      return callerName;
    }
  }

  /// Save call status into Firestore history
  Future<void> _saveCallHistory(String status) async {
    final now = Timestamp.now();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection("call_history").add({
      "callerId": callerId,
      "receiverId": receiverId,
      "callType": callType,
      "status": status,
      "starttime": now,
      "endTime": status == "accepted" ? null : now,
      "userId": userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final CallService callService = CallService();

        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: FutureBuilder<String>(
              future: _fetchCallerName(),
              builder: (context, snapshotName) {
              final name = snapshotName.data ?? callerName;
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                    callType == "audio" ? Icons.call: Icons.videocam, size: 100, color: Colors.greenAccent),
                    const SizedBox(height: 20),
                    Text("Incoming ${callType.toUpperCase()} Call", style: const TextStyle(color: Colors.white, fontSize: 22),),
                    const SizedBox(height: 10),
                    Text("From: $name", style: const TextStyle(color: Colors.white70, fontSize: 18),),
                    const SizedBox(height: 40),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () async {
                            await callService.rejectCall(callId);
                            await _saveCallHistory("rejected");
                            if (context.mounted) Navigator.maybePop(context);
                          },
                          child: const Icon(Icons.call_end, color: Colors.white),
                        ),
                        const SizedBox(width: 30),
                        // Accept
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          onPressed: () async {
                            await callService.acceptCall(callId);
                            await _saveCallHistory("accepted");

                            final doc = await FirebaseFirestore.instance.collection('calls').doc(callId).get();
                            final data = doc.data() ?? {};
                            final receiverToken = data['receiverToken'];
                            final receiverUid = data['receiverUid'];

                            if (receiverToken == null || receiverUid == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Token is missing!")),);
                              return;
                            }
                            if (callType == "audio") {
                              navigatorkey.currentState?.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      AudioCallScreen(
                                        channelName: callId,
                                        receiverId: receiverId,
                                        receiverName: name,
                                        token: receiverToken,
                                      ),
                                ),
                              );
                            } else {
                              navigatorkey.currentState?.pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VideoCallScreen(
                                        channelName: callId,
                                        receiverId: receiverId,
                                        receiverName: name,
                                        token: receiverToken,
                                      ),
                                 ),
                              );
                            }
                          },
                          child: const Icon(Icons.call, color: Colors.white),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),
    );
  }
}
