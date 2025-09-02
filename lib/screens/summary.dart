import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nivetha123/screens/user_data.dart';
import 'package:nivetha123/screens/checkbox_animation_page.dart';
import '../main.dart';
import '../widgets/step_progress.dart';

class Page5Summary extends StatefulWidget {
  final UserData userData;

  const Page5Summary({Key? key, required this.userData}) : super(key: key);

  @override
  _Page5SummaryState createState() => _Page5SummaryState();
}

class _Page5SummaryState extends State<Page5Summary> {
  bool termsAccepted = false;

  String generatedUserId = '';
  bool isUserIdLoading = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUserId();
  }

  void _initializeUserId() async {
    if (generatedUserId.isEmpty) {
      final id = await _generateUniqueUserId(widget.userData.role);
      setState(() {
        generatedUserId = id;
        isUserIdLoading = false;
      });
    }
  }

  Future<String> _generateUniqueUserId(String role) async {
    String prefix = role == 'Worker' ? 'WO' : 'JO';

    final metaDoc = FirebaseFirestore.instance
        .collection('meta')
        .doc('lastUserId');
    final snapshot = await metaDoc.get();

    int lastId = 1000;
    if (snapshot.exists && snapshot.data()?['last'] != null) {
      lastId = snapshot.data()!['last'];
    }

    int newId = lastId + 1;

    await metaDoc.set({'last': newId});

    return '$prefix${newId.toString().padLeft(4, '0')}';
  }

  Future<String?> _convertImageToBase64(String imagePath) async {
    try {
      File imageFile = File(imagePath);
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    } catch (e) {
      print("Image conversion failed: $e");
      return null;
    }
  }

  void _saveToFirebase() async {
    if (!termsAccepted || isUserIdLoading || _isLoading) return;

    setState(() => _isLoading = true);

    String? base64Image;
    if (widget.userData.role == 'Worker' &&
        widget.userData.profileImage != null &&
        widget.userData.profileImage!.isNotEmpty) {
      base64Image = await _convertImageToBase64(widget.userData.profileImage!);
    }

    final userId = generatedUserId;
    final sanitizedEmail = globalEmail.replaceAll('.', 'dot');

    Map<String, dynamic> userDataMap = {
      "userId": userId,
      "name": widget.userData.name,
      "role": widget.userData.role,
      "gender": widget.userData.gender,
      "dob": widget.userData.dob?.toIso8601String() ?? "Not Set",
      "phone": widget.userData.phoneNumber,
      "country": widget.userData.country,
      "state": widget.userData.state,
      "district": widget.userData.district,
      "city": widget.userData.city,
      "area": widget.userData.area,
      "address": widget.userData.address,
      "experience":
          widget.userData.role == 'Worker' ? widget.userData.experience : "N/A",
      "email-id": globalEmail,
      "profileImageBase64": base64Image ?? "No Image",
    };

    try {
      final userType =
          widget.userData.role == "Worker" ? "workers" : "jobproviders";

      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userType)
          .collection(userType)
          .doc(userId);

      await userDoc.set(userDataMap);

      await FirebaseFirestore.instance
          .collection('emails')
          .doc(sanitizedEmail)
          .set({'userId': userId});

      widget.userData.userId = userId;

      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => CheckboxAnimationPage(
                success: true,
                userData: widget.userData,
              ),
        ),
      );
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save data: $error'),
          action: SnackBarAction(label: 'Retry', onPressed: _saveToFirebase),
        ),
      );
    }
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
              'Profile Overview',
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          StepProgress(currentStep: 5, totalSteps: 5),
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
                                  Center(
                                    child: Column(
                                      children: [
                                        if (widget.userData.role == 'Worker')
                                          CircleAvatar(
                                            radius: 55,
                                            backgroundColor: Colors.grey[200],
                                            backgroundImage:
                                                widget.userData.profileImage !=
                                                        null
                                                    ? FileImage(
                                                      File(
                                                        widget
                                                            .userData
                                                            .profileImage!,
                                                      ),
                                                    )
                                                    : null,
                                            child:
                                                widget.userData.profileImage ==
                                                        null
                                                    ? const Icon(
                                                      Icons.person,
                                                      size: 55,
                                                      color: Color(0xFF512DA8),
                                                    )
                                                    : null,
                                          ),
                                        SizedBox(height: 12),
                                        Text(
                                          'User ID',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1A237E),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEDE7F6),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF2563EB),
                                              width: 1,
                                            ),
                                          ),
                                          child:
                                              isUserIdLoading
                                                  ? const SizedBox(
                                                    height: 25,
                                                    width: 25,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF2563EB,
                                                          ),
                                                        ),
                                                  )
                                                  : Text(
                                                    generatedUserId,
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF2563EB),
                                                    ),
                                                    textAlign: TextAlign.center,
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 28),
                                  Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow('User Id:', generatedUserId),
                                  _buildInfoRow('Name:', widget.userData.name),
                                  _buildInfoRow('Role:', widget.userData.role),
                                  _buildInfoRow(
                                    'Gender:',
                                    widget.userData.gender,
                                  ),
                                  _buildInfoRow(
                                    'DOB:',
                                    widget.userData.dob
                                            ?.toLocal()
                                            .toString()
                                            .split(' ')[0] ??
                                        "Not Set",
                                  ),
                                  SizedBox(height: 24),
                                  Text(
                                    'Contact Details',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A237E),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildInfoRow(
                                    'Phone:',
                                    widget.userData.phoneNumber,
                                  ),
                                  _buildInfoRow(
                                    'Country:',
                                    widget.userData.country,
                                  ),
                                  _buildInfoRow(
                                    'State:',
                                    widget.userData.state,
                                  ),
                                  _buildInfoRow(
                                    'District:',
                                    widget.userData.district,
                                  ),
                                  _buildInfoRow('City:', widget.userData.city),
                                  _buildInfoRow('Area:', widget.userData.area),
                                  _buildInfoRow(
                                    'Address:',
                                    widget.userData.address,
                                  ),
                                  if (widget.userData.role == 'Worker') ...[
                                    SizedBox(height: 24),
                                    Text(
                                      'Experience',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A237E),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    _buildInfoRow(
                                      'Experience:',
                                      widget.userData.experience,
                                    ),
                                  ],
                                  SizedBox(height: 24),
                                  CheckboxListTile(
                                    value: termsAccepted,
                                    onChanged: (value) {
                                      setState(() {
                                        termsAccepted = value ?? false;
                                      });
                                    },
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: const Text(
                                      'I accept the Terms & Conditions',
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF2563EB),
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
                              onPressed:
                                  (termsAccepted &&
                                          !isUserIdLoading &&
                                          !_isLoading)
                                      ? _saveToFirebase
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    (termsAccepted && !isUserIdLoading)
                                        ? const Color(0xFF2563EB)
                                        : Colors.blue,
                                padding: EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                              ),
                              icon: Icon(Icons.check, color: Colors.white),
                              label: Text(
                                'Submit',
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              textAlign: TextAlign.end,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
