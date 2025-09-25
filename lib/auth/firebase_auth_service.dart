import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //signup user with email and password
  Future<User?> signUpWithEmail(String email, String password) async {
   final result = await _auth.createUserWithEmailAndPassword( email: email, password: password);
   final user = result.user;

      if(user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'createAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,

          // reserve fields to avoid null check later
          'name': '',
          'gender': '',
          'language': '',
          'country': '',
          'base64Image': '',
        }, SetOptions(merge: true));
      }
      return user;
  }

  //login user with email and password
  Future<User?> loginWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    }

  //forgot password
  Future<void> sendPasswordReset(String email) async {
      await _auth.sendPasswordResetEmail(email: email);
    }
  //log out
  Future<void> signOut() async =>  _auth.signOut();

 User? getCurrentUser() =>  _auth.currentUser;
}



