import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'user_list_page.dart';
import 'call_history_page.dart';
import 'settings_page.dart';
import 'notifications_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

       final List<Widget> _pages = [
       const DashboardPage(), // Home
       const UserListPage(), // Users
       const CallHistoryPage(), // Calls
       const NotificationsPage(), // Notifications
       const SettingsPage(), // Settings
     ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.call),
            label: 'Calls',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Dashboard (Home Page)
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<Map<String, dynamic>?> _getCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) return null;
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.orange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Row(
          children: const [
            Icon(Icons.phone, color: Colors.white),
            SizedBox(width: 8),
            Text("MatchCall", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold,
               ),
             ),
          ],
        ),
        centerTitle: false,
      ),

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

          child: FutureBuilder<Map<String, dynamic>?>(
          future: _getCurrentUserData(),
              builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text("No profile data found"));
              }

              final userData = snapshot.data!;
              final base64Image = userData['profileImage'] ?? "";
              final name = userData['name'] ?? "User";

              return Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              // Profile Picture
              CircleAvatar(
              radius: 60,
              backgroundImage: base64Image.isNotEmpty ? MemoryImage(base64Decode(base64Image)) : null,
              child: base64Image.isEmpty ? const Icon(Icons.person, size: 60) : null,
              ),
              const SizedBox(height: 16),

              // Name
              Text( name, style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold,
               ),
              ),

              const SizedBox(height: 12),

                const Text(
            "Talk. Connect.Match the vibe!",
            style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: Colors.deepPurple,
                  ),
                 textAlign: TextAlign.center,
                         ),
                       ],
                     ),
               );
             },
          ),
        ),
      );
    }
  }
