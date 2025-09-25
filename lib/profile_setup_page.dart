import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'pages/home_screen.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});
  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedCountry;

List<String> _languages = [];
List<String> _countries = [];

File? _imageFile;
String? _base64Image;
bool _isLoading = false;

@override
  void initState() {
  super.initState();
  _loadCountries();
  _loadLanguages();
}

Future<void> _loadCountries() async {
  final String response = await rootBundle.loadString('assets/data/countries.json');
  final data = await json.decode(response);
  setState(() {
    _countries = List<String>.from(data);
  });
}

  Future<void> _loadLanguages() async {
    final String response = await rootBundle.loadString('assets/data/languages.json');
    final data = await json.decode(response);
    setState(() {
      _languages = List<String>.from(data);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64String = base64Encode(imageBytes);

      setState(() {
        _imageFile = imageFile;
        _base64Image = base64String;
      });
    }
  }

  Future<void> _saveProfile() async {
  if(!_formKey.currentState!.validate() || _selectedGender == null || _selectedCountry == null || _selectedLanguage == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
    return ;
  }
  setState(() => _isLoading = true);

  try{
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameController.text.trim(),
      'gender': _selectedGender,
      'language': _selectedLanguage,
      'country': _selectedCountry,
      'profileImage': _base64Image ?? '',
      'profileCompleted': true,
    }, SetOptions(merge: true));

    if(mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
  } finally {
    setState(() => _isLoading = false);
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Pick from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Take a Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text("Profile Setup")),
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
      child: _isLoading
               ? const Center(child: CircularProgressIndicator())
               : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          GestureDetector(
                            onTap: _showImageSourceOptions,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                              child: _imageFile == null ? const Icon(Icons.add_a_photo, size: 40) : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Name'),
                            validator: (value) => value!.isEmpty ? 'Enter your name' : null,
                          ),

                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                              value: _selectedGender,
                              items: ['Male', 'Female', 'Other']
                                       .map((gender) => DropdownMenuItem(value: gender, child: Text(gender)))
                                       .toList(),
                              onChanged: (value) => setState(() => _selectedGender = value),
                              decoration: const InputDecoration(labelText: 'Gender'),
                          ),

                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedLanguage,
                            items: _languages
                                .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedLanguage = value),
                            decoration: const InputDecoration(labelText: 'Language'),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String>(
                            value: _selectedCountry,
                            items: _countries
                                .map((country) => DropdownMenuItem(value: country, child: Text(country)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedCountry = value),
                            decoration: const InputDecoration(labelText: 'Country'),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text('Save Profile'),
                          ),
                        ],
                      ),
                    ),
                 ),
    ),
     );
  }
}

