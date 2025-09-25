import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  ///mark notification as read
  void _markAsRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  ///mark all notification as read
  void _markAllAsRead(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('receiverId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }



  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return  Scaffold(
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (userId != null)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: "Mark all as read",
              onPressed: () => _markAllAsRead(userId),
            ),
        ],
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

        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .where('receiverId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No notifications available"));
            }

            final notifications = snapshot.data!.docs;
            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notif = notifications[index];
                final data = notif.data() as Map<String, dynamic>;
                final title = notif['title'] ?? "Notification";
                final body = notif['body'] ?? "";
                final timestamp = (notif['timestamp'] as Timestamp).toDate();
                final formattedTime = DateFormat("dd-MM-yyyy hh:mm a").format(timestamp);
                final isRead = data['isRead'] ?? false;

                return ListTile(
                  title: Text(title, style: TextStyle(color: Colors.white, fontWeight: isRead ? FontWeight.normal : FontWeight.bold,)),
                  subtitle: Text(body, style: const TextStyle(color: Colors.white70)),
                  trailing: Column(crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(formattedTime, style: const TextStyle(color: Colors.white54, fontSize: 12),),
                    if (!isRead)
                        const Icon(Icons.circle, color: Colors.blue, size: 10),
                 ],
                ),
                onTap: () => _markAsRead(notif.id),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
