import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/agora_service.dart';
import '../services/fcm_token_service.dart';

class CallService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Start a new call
  Future<void> startCall({
    required String receiverId,
    required String receiverName,
    required String callType, // "audio" or "video"
  }) async {
    try {
      final callerId = _auth.currentUser!.uid;
      final callId = DateTime.now().millisecondsSinceEpoch.toString();
      final callerUid = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
      final callerToken = await fetchToken(callId, callerUid);
      if (callerToken == null) throw Exception("Token fetch failed");

      final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
      final receiverToken = receiverDoc.data()?['fcmToken'];

      /// Save call details to Firestore
      await _firestore.collection('calls').doc(callId).set({
        'callId': callId,
        'channelName': callId,
        'callerId': callerId,
        'callerUid': callerUid,
        'callerToken': callerToken,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'receiverToken': receiverToken,
        'callType': callType,
        'status': 'ringing', // ringing | accepted | ended
        'timestamp': FieldValue.serverTimestamp(),
      });
      ///send notification to receiver
      await _sendFCMNotification(receiverId, callerId, callType, callId);
    } catch (e) {
      print("Error in startCall: $e");
    }
  }

  /// Accept call
  Future<void> acceptCall(String callId) async {
    try {
      final docRef =  _firestore.collection('calls').doc(callId);
      final doc = await docRef.get();
      final callData = doc.data();
      if(callData == null) throw Exception("Call not found");
      final receiverUid = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
      final receiverToken = await fetchToken(callId, receiverUid);
      if(receiverToken == null) throw Exception("Token fetch failed");

      await docRef.update({
        'status': 'accepted',
        'receiverUid': receiverUid,
        'receiverToken': receiverToken,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error in acceptCall: $e");
    }
  }

  /// Reject call
  Future<void> rejectCall(String callId) async {
    try {
      await _firestore.collection('calls').doc(callId).update({'status': 'declined'});
    } catch (e) {
      print("Error in rejectCall: $e");
    }
  }

  /// End call
  Future<void> endCall({
    required String channelName,
    required String receiverId,
    required String receiverName,
    required String callType,
    required DateTime startTime,
}) async {
    try {
      final callerId = _auth.currentUser!.uid;
      final endTime = DateTime.now();

      await _firestore.collection('calls').doc(channelName).update({'status': 'ended'});

      ///save permanent history
      await _firestore.collection('call_history').add({
        'callerId': callerId,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'callType': callType,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
      });

      await _firestore.collection('calls').doc(channelName).delete();
    } catch (e) {
      print("Error in endCall: $e");
    }
  }

  /// Listen for incoming call
  Stream<DocumentSnapshot<Map<String, dynamic>>> callStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots();
  }

  ///send FCM notification to receiver
  Future<void> _sendFCMNotification(String receiverId, String callerId, String callType, String callId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(receiverId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      if(fcmToken == null) return;
      final callerDoc = await _firestore.collection('users').doc(callerId).get();
      final callerName = callerDoc.data()?['name'] ?? "Unknown";

      final accessToken = await getAccessToken('assets/callconnectapp-firebase-adminsdk.json');

      final body = {
        'message': {
          "token": fcmToken,
          "android": {
            "priority": "high",
            "notification": {
              "sound": "default",
              "channelId": "calls"
            }
          },
          "notification": {
            "title": "Incoming ${callType.toUpperCase()} Call",
            "body": "$callerName is calling you..."
          },
          "data": {
                   "callId": callId,
                   "callType": callType,
                   "callerId": callerId,
                   "callerName": "Unknown",
                   "callerAvatar": "",
                   "type": "call"
          }
        }
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/callconnectapp/messages:send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(body),
      );
      print("FCM response: ${response.body}");

      ///  Save notification to Firestore
      await _firestore.collection('notifications').add({
        "receiverId": receiverId,
        "callerId": callerId,
        "callerName": callerName,
        "callType": callType,
        "callId": callId,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "unread",
        "type": "call",
      });

    } catch (e) {
      print("Error sending FCM notification: $e");
    }
  }
}
