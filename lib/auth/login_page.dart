import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/firebase_auth_service.dart';
import '../profile_setup_page.dart';
import '../pages/home_screen.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = FirebaseAuthService();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  Future<void> loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      );

       final uid = FirebaseAuth.instance.currentUser!.uid;
       final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
       final profileCompleted = (userDoc.data()?['profileCompleted'] ?? false) == true;

      if(!profileCompleted){
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
          );
        }
      } else {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Login failed: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> resetPassword() async {
    if(_emailController.text.trim().isEmpty) {
      Fluttertoast.showToast(msg: "Enter your email to reset password");
      return;
    }

    try {
      await _authService.sendPasswordReset(_emailController.text.trim(),);
      Fluttertoast.showToast(msg: "Reset link sent to email");
    } catch (e) {
      Fluttertoast.showToast(msg: "Error: ${e.toString()}");
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
      appBar: AppBar(title: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if(value ==  null || !value.contains('@')) { return "Enter a valid email"; }
                        return null;
          },
            ),
              const SizedBox(height: 16),
              TextFormField(controller: _passwordController, obscureText: !_isPasswordVisible, decoration: InputDecoration(labelText: 'Password',
                    suffixIcon: IconButton(
                               icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                                 setState(() {
                                   _isPasswordVisible = !_isPasswordVisible;
                                 });
                            },
                        ),
                     ),
               validator: (value) {
                if(value == null || value.length < 6) {
                  return "Password must be at least 6 characers";
              }
                return null;
           },
             ),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                       onPressed: resetPassword,
                       child: const Text("Forgot Password?"),
         ),
            ),
              const SizedBox(height: 20),
              _isLoading ? const CircularProgressIndicator() :
              ElevatedButton(onPressed: loginWithEmail, child: const Text("Login"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  );
                },
                child: const Text("Don't have an account? Sign up"),
                ),
            ],
          ),
         ),
        ),
      ),
    );
  }
}


//adb shell ip route
//adb tcpip 5555
//adb connect 100.83.32.251:5555
//adb devices
//flutter run -d 100.83.32.251:5555

