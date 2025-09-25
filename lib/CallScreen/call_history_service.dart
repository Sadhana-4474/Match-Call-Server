import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallHistoryService {
  static Future<void> saveCall({
    required String receiverId,
    required String receiverName,
    required String callType,
    required String status,
    DateTime? startTime,
    DateTime? endTime,
}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    int durationSeconds = 0;
    if(startTime != null && endTime != null) {
      durationSeconds = endTime.difference(startTime).inSeconds;
    }

/// for user
    await FirebaseFirestore.instance.collection('call_history').add({
      'userId': currentUser.uid,
      'userName': currentUser.displayName ?? '',
      'receiverId': receiverId,
      'receiverName': receiverName,
      'callType': callType,
      'status': status,
      'duration': durationSeconds,
      'timestamp': FieldValue.serverTimestamp(),
      'isCaller': true,
    });

    ///for receiver
    await FirebaseFirestore.instance.collection('call_history').add({
      'userId': receiverId,
      'userName': receiverName,
      'receiverId': currentUser.uid,
      'receiverName': currentUser.displayName ?? '',
      'callType': callType,
      'status': status,
      'duration': durationSeconds,
      'timestamp': FieldValue.serverTimestamp(),
      'isCaller': false,
    });
  }

  static Future<void> endCall({
    required String channelName,
    required String receiverId,
    required String receiverName,
    required String callType,
    required DateTime startTime,
  }) async {
    final endTime = DateTime.now();

    await saveCall(
      receiverId: receiverId,
      receiverName: receiverName,
      callType: callType,
      status: "completed", // default end status
      startTime: startTime,
      endTime: endTime,
    );
  }
}