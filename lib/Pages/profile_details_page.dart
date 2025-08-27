import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/user_data.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

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

  final List<String> profileImages = [
    'assets/images/profile1.png',
    'assets/images/profile2.png',
    'assets/images/profile3.png',
  ];

  int selectedProfileIndex = 0;

  @override
  void initState() {
    super.initState();
    userData = widget.userData;
    _loadSelectedProfileIndex();
    _loadSavedProfileImage();
  }

  Future<void> _loadSelectedProfileIndex() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedProfileIndex = prefs.getInt('profileIndex') ?? 0;
    });
  }

  Future<void> _saveSelectedProfileIndex(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('profileIndex', index);
  }

  Future<void> _loadSavedProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedPath = prefs.getString('localProfileImage_${userData.userId}');
    if (savedPath != null && savedPath.isNotEmpty) {
      setState(() {
        userData.profileImage = savedPath;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        userData.profileImage = picked.path;
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'localProfileImage_${userData.userId}',
        picked.path,
      );
    }
  }

  Widget _buildEditableField(
    String label,
    String value,
    void Function(String) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildUserInfoCard(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100, width: 1.5),
      ),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile() async {
    final rolePath =
        userData.role.toLowerCase() == 'worker' ? 'workers' : 'jobproviders';

    final DocumentReference ref = FirebaseFirestore.instance
        .collection('users')
        .doc(rolePath)
        .collection(rolePath)
        .doc(userData.userId);

    await ref.set(userData.toJson());

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userData', jsonEncode(userData.toJson()));
    await _saveSelectedProfileIndex(selectedProfileIndex);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Profile saved successfully')));

    Navigator.pop(context, userData);
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider avatarImage;

    if (userData.profileImage != null &&
        userData.profileImage!.isNotEmpty &&
        File(userData.profileImage!).existsSync()) {
      avatarImage = FileImage(File(userData.profileImage!));
    } else {
      avatarImage = AssetImage(profileImages[selectedProfileIndex]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Details'),
        backgroundColor: Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue.shade200, width: 3),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: avatarImage,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.edit, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // User info cards at the top
          _buildUserInfoCard('Role', userData.role),
          _buildUserInfoCard('User ID', userData.userId),
          const SizedBox(height: 8),
          Divider(thickness: 1, height: 20, indent: 20, endIndent: 20),
          const SizedBox(height: 8),
          // Editable fields
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton(
              onPressed: _saveProfile,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'SAVE CHANGES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
