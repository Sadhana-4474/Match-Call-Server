import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../profile_setup_page.dart';
import '../auth/signup_page.dart';
import '../auth/login_page.dart';
import '../main.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await FirebaseAuth.instance.signOut();
    await prefs.setBool("hasSignedUp", true);
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
    );
  }

  void changePassword() async {
    if (user?.email != null) {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset email sent")),
      );
    }
  }

  Future<void> deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Delete"),
              onPressed: () async {
                Navigator.pop(context);

                try {
                  //delete firestore document
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).delete();

                  //delete firebase auth account
                  await user!.delete();

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool("hasSignedUp", false);

                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpPage()),
                      (route) => false,
                  );
                } on FirebaseAuthException catch (e) {
                  if (e.code == 'requires-recent-login') {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Please log in again to delete your account."),
                          ),
                        );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: ${e.message}")),
                    );
                  }
                }
              },
            ),
        ],
      ),
     );
    }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
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
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              onTap: changePassword,
            ),
              SwitchListTile(
               title: const Text("Enable Notifications"),
               value: notificationsEnabled,
               onChanged: (value) {
                 setState(() => notificationsEnabled = value);
               },
                secondary: const Icon(Icons.notifications),
            ),
            SwitchListTile(
                title: const Text("Dark Mode"),
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme(value);
                },
              secondary: const Icon(Icons.dark_mode),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: logout,
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text("Delete Account",
              style: TextStyle(color: Colors.red),
              ),
              onTap: deleteAccount,
            ),
          ],
        ),
      ),
    );
  }
}