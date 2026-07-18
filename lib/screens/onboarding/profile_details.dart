import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:nivetha123/screens/onboarding/summary.dart';
import 'package:nivetha123/models/user_data.dart';

import '../../theme/branding.dart';
import '../../widgets/step_progress.dart';

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
      showWNMessage(context, isError: true, message: 'Please upload a profile picture!');
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
      backgroundColor: WNColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Profile Info',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: WNColors.navy,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StepProgress(currentStep: 4, totalSteps: 5),

                  SizedBox(height: 30),

                  // 📸 Profile Picture Upload
                  Text(
                    'Upload Profile Picture',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: WNColors.navy),
                  ),
                  SizedBox(height: 15),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: WNColors.blue, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            _image != null ? FileImage(_image!) : null,
                        child:
                            _image == null
                                ? Icon(
                                  Icons.camera_alt,
                                  size: 35,
                                  color: WNColors.blue,
                                )
                                : null,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // 🏆 Experience Input Field
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Years of Experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: WNColors.navy,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  TextField(
                    controller: experienceController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 3',
                      prefixIcon: const Icon(Icons.work_outline, color: WNColors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        errorMessage = null;
                      });
                    },
                  ),

                  if (errorMessage != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔄 Fixed Navigation Buttons at Bottom
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WNColors.blue,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Back', style: TextStyle(color: Colors.white)),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _validateAndProceed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: WNColors.blue,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text('Next', style: TextStyle(color: Colors.white)),
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
