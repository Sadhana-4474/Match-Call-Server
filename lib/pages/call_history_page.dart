import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CallHistoryPage extends StatelessWidget {
  const CallHistoryPage({super.key});

  String formatDuration(int seconds) {
    final minutes = seconds ~/60;
    final remainingSeconds = seconds % 60;
    return "${minutes}m ${remainingSeconds}s";
  }

  IconData getCallIcon(String type) {
    switch (type) {
      case "ringing":
      case "incoming":
      return Icons.call_received;
      case "outgoing":
        return Icons.call_made;
      case "accepted":
      case "received":
        return Icons.call;
      case "missed":
        return Icons.call_missed;
      default:
        return Icons.call;
    }
  }

  Color getCallColor(String type) {
    switch (type) {
      case "missed":
      return Colors.red;
      case "ringing":
      case "incoming":
        return Colors.blue;
      case "outgoing":
        return Colors.green;
      case "accepted":
      case "received":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Call History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              Color(0xFFBBDEFB), // light blue
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('call_history')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              print("Firestore Error: ${snapshot.error}");
              return Center(
                  child: Text("Error loading call history: ${snapshot.error}"));
            }
            if(!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No call history available"));
            }

            final calls = snapshot.data!.docs;

            return ListView.builder(
              itemCount: calls.length,
              itemBuilder: (context, index) {
                final call = calls[index].data() as Map<String, dynamic>;
                final type = call['status'] ?? "unknown";
                final name =  call['userId'] == userId ? call['receiverName'] ?? "Unknown" : call['userName'] ?? "Unknown";
                final duration = (call['duration'] ?? 0) is int ? call['duration'] : 0;
                final timestamp = call['timestamp'] is Timestamp ? (call['timestamp'] as Timestamp).toDate() : DateTime.now();
                final timeFormatted = DateFormat("hh:mm a").format(timestamp);
                final dateFormatted = DateFormat("dd-MM-yyyy").format(timestamp);

                return ListTile(
                  leading: Icon(
                    getCallIcon(type),
                    color: getCallColor(type),
                  ),
                  title: Text(name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    "${formatDuration(duration)} | $timeFormatted | $dateFormatted",
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}