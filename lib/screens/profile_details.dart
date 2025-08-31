import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nivetha123/screens/summary.dart';
import 'package:nivetha123/screens/user_data.dart';

import '../widgets/step_progress.dart';

class Page4ProfileDetails extends StatefulWidget {
  final UserData userData;
  Page4ProfileDetails({required this.userData});

  @override
  _Page4ProfileDetailsState createState() => _Page4ProfileDetailsState();
}

class _Page4ProfileDetailsState extends State<Page4ProfileDetails> {
  File? _image;
  TextEditingController experienceController = TextEditingController();
  String? errorMessage;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        widget.userData.profileImage = pickedFile.path;
      });
    }
  }

  void _validateAndProceed() {
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload a profile picture!')),
      );
      return;
    }

    if (experienceController.text.isEmpty) {
      setState(() {
        errorMessage = "Please enter your years of experience.";
      });
      return;
    }

    widget.userData.experience = experienceController.text;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Page5Summary(userData: widget.userData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Icon(Icons.account_circle, color: Colors.white, size: 28),
            SizedBox(width: 10),
            Text(
              'Profile Info',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2563EB),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
        ),
        toolbarHeight: 65,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StepProgress(currentStep: 4, totalSteps: 5),
                  SizedBox(height: 32),
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 28,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upload Profile Picture',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                padding: EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF2563EB),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 65,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage:
                                      _image != null
                                          ? FileImage(_image!)
                                          : null,
                                  child:
                                      _image == null
                                          ? Icon(
                                            Icons.camera_alt,
                                            size: 35,
                                            color: const Color(0xFF2563EB),
                                          )
                                          : null,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 32),
                          Text(
                            'Years of Experience',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A237E),
                            ),
                          ),
                          SizedBox(height: 12),
                          TextField(
                            controller: experienceController,
                            decoration: InputDecoration(
                              labelText: 'Enter your years of experience',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Color(0xFF2563EB),
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            onChanged: (value) {
                              setState(() {
                                errorMessage = null;
                              });
                            },
                          ),
                          if (errorMessage != null)
                            Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                    ),
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    label: Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _validateAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                      ),
                      icon: Icon(Icons.arrow_forward, color: Colors.white),
                      label: Text(
                        'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
