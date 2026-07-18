import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/user_data.dart';
import '../login/branding.dart';

class ProfileDetailsPage extends StatefulWidget {
  final UserData userData;

  const ProfileDetailsPage({Key? key, required this.userData})
    : super(key: key);

  @override
  _ProfileDetailsPageState createState() => _ProfileDetailsPageState();
}

class _ProfileDetailsPageState extends State<ProfileDetailsPage> {
  late UserData userData;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final base64Image = await compressImageToBase64(picked.path);
    if (base64Image == null) {
      if (mounted) await showWNMessage(context, isError: true, message: 'Failed to process image.');
      return;
    }

    setState(() {
      userData.profileImage = base64Image;
    });
  }

  Widget _buildEditableField(
    String label,
    String value,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: TextFormField(
        initialValue: value,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: WNColors.blue, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Determine path based on role
    final rolePath =
        userData.role.toLowerCase() == 'worker' ? 'workers' : 'jobproviders';

    // Save to Firebase under correct role path
    final DocumentReference ref = FirebaseFirestore.instance
        .collection('users')
        .doc(rolePath)
        .collection(rolePath)
        .doc(userData.userId);


    await ref.set(userData.toJson());

    // Save to SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData.toJson()));

    if (!mounted) return;
    await showWNMessage(context, message: 'Profile saved successfully');
    if (!mounted) return;
    Navigator.pop(context, userData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      appBar: AppBar(
        title: const Text(
          'Profile Details',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: WNColors.blue,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 24),
          Center(
            child: Stack(
              children: [
                WNAvatar(imageBase64: userData.profileImage, name: userData.name, radius: 50),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: WNColors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildEditableField(
            'Name',
            userData.name,
            (val) => userData.name = val,
          ),
          _buildEditableField(
            'Phone',
            userData.phoneNumber,
            (val) => userData.phoneNumber = val,
          ),
          _buildEditableField(
            'Role',
            userData.role,
            (val) => userData.role = val,
          ),
          _buildEditableField(
            'Gender',
            userData.gender,
            (val) => userData.gender = val,
          ),
          _buildEditableField(
            'DOB',
            userData.dob?.toLocal().toString().split(' ')[0] ?? '',
            (val) => userData.dob = DateTime.tryParse(val),
          ),
          _buildEditableField(
            'Country',
            userData.country,
            (val) => userData.country = val,
          ),
          _buildEditableField(
            'State',
            userData.state,
            (val) => userData.state = val,
          ),
          _buildEditableField(
            'District',
            userData.district,
            (val) => userData.district = val,
          ),
          _buildEditableField(
            'City',
            userData.city,
            (val) => userData.city = val,
          ),
          _buildEditableField(
            'Area',
            userData.area,
            (val) => userData.area = val,
          ),
          _buildEditableField(
            'Address',
            userData.address,
            (val) => userData.address = val,
          ),
          if (userData.role.toLowerCase() == 'worker')
            _buildEditableField(
              'Experience',
              userData.experience ?? '',
              (val) => userData.experience = val,
            ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: WNColors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
