import 'package:matchcall/auth/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool _isLoading = false;

 final FirebaseAuthService _authService = FirebaseAuthService();

 Future<void> signUpWithEmail() async {
   if (!_formkey.currentState!.validate()) return;

   setState(() => _isLoading = true);
    try {
      final user = await _authService.signUpWithEmail(
         _emailController.text.trim(),
         _passwordController.text.trim(),
      );

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'email': _emailController.text.trim(),
          'createAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,
        }, SetOptions(merge: true));

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("hasSignedUp", true);

      Fluttertoast.showToast(msg: "Signup successful");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Signup failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
 }

   @override
   void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.orange],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFE0B2),
              Color(0xFFE1BEE7),
              Color(0xFFBBDEFB), // light blue for smooth blend
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
           key: _formkey,
           child: Column(
            children: [
              TextFormField(controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || !value.contains('@')) {
                      return "Enter a valid email";
           }
                    return null;
         },
            ),
               const SizedBox(height: 12),
              TextFormField(controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if(value ==  null || value.length < 6) {
                      return "Password must be at least 6 characters";
         }
                    return null;
         },
            ),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() :
              ElevatedButton(onPressed: signUpWithEmail, child: const Text("Sign Up")),

              TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text("Already have an account? Login"),
              ),
            ],
          ),
         ),
        ),
      ),
    );
  }
}

