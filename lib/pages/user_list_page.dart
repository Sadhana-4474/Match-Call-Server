import 'dart:convert'; // for base64 decode
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../CallScreen/VideoCallScreen.dart';
import '../CallScreen/AudioCallScreen.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Users", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No users found"));
          }

          final users = snapshot.data!.docs;

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index].data() as Map<String, dynamic>;
                final id = users[index].id;

                final name = (user['name'] ?? "Unnamed User").toString();
                final email = (user['email'] ?? "").toString();
                final gender = (user['gender'] ?? "").toString();
                final language = (user['language'] ?? "Not specified").toString();
                final base64Image = user['profileImage'] as String?;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (base64Image != null && base64Image.isNotEmpty) ? MemoryImage(base64Decode(base64Image)) : null,
                    child: (base64Image == null || base64Image.isEmpty) ? const Icon(Icons.person) : null,
                  ),
                  title: Text(name),
                  subtitle: Text(language),
                  onTap: () {
                    Navigator.push(
                      context, MaterialPageRoute(
                      builder: (_) => UserDetailPage(
                            userId: id,
                            name: name,
                            email: email,
                            gender: gender,
                            language: language,
                            base64Image: base64Image ?? "",
                          ),
                        ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class UserDetailPage extends StatelessWidget {
  final String userId;
  final String name;
  final String email;
  final String gender;
  final String language;
  final String base64Image;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.name,
    required this.email,
    required this.gender,
    required this .language,
    required this.base64Image,
});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            Color(0xFFFFE0B2),
            Color(0xFFE1BEE7),
            Color(0xFFBBDEFB),
          ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(radius: 50,
                backgroundImage: (base64Image.isNotEmpty) ? MemoryImage(base64Decode(base64Image)) : null,
                child: base64Image.isEmpty ? const Icon(Icons.person, size: 50) : null,
                ),
                const SizedBox(height: 20),
                Text( name, style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold),
                  ),

            const SizedBox(height: 8),
            if (email.isNotEmpty)
            Text(email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 10),

                Text(language, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 30),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => AudioCallScreen(channelName: "test_channel", receiverId: userId, receiverName: name, token: "token",
                          ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label:const Text("Audio Call"),
                ),
                const SizedBox(height:10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (_) => VideoCallScreen(channelName: "test_channel", receiverId: userId, receiverName: name, token: "token",
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam),
                  label:const Text("Video Call"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}