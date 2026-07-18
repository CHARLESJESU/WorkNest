import 'package:flutter/material.dart';
import 'package:nivetha123/screens/onboarding/personal_details.dart';
import 'package:nivetha123/models/user_data.dart';
import '../../theme/branding.dart';
import '../../widgets/step_progress.dart';

class Page1NameRole extends StatefulWidget {
  final UserData userData;
  Page1NameRole({required this.userData});

  @override
  _Page1NameRoleState createState() => _Page1NameRoleState();
}

class _Page1NameRoleState extends State<Page1NameRole> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole; // Store the selected role separately for validation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'User Profile',
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
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StepProgress(currentStep: 1, totalSteps: 5),

                    SizedBox(height: 30),

                    // Name Input
                    Text(
                      'What Should We Call You?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WNColors.navy,
                      ),
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Your Name',
                        prefixIcon: const Icon(Icons.person_outline, color: WNColors.blue),
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Name is required'
                                  : null,
                      onChanged: (value) => widget.userData.name = value,
                    ),

                    SizedBox(height: 30),

                    // Role Selection with Radio Buttons
                    Text(
                      'What is your role?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: WNColors.navy,
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            title: Text('Worker', style: TextStyle(fontSize: 16)),
                            value: 'Worker',
                            groupValue: selectedRole,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value;
                                widget.userData.role = value!;
                              });
                            },
                            activeColor: WNColors.blue,
                          ),
                          RadioListTile<String>(
                            title: Text(
                              'Job Provider',
                              style: TextStyle(fontSize: 16),
                            ),
                            value: 'Job Provider',
                            groupValue: selectedRole,
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value;
                                widget.userData.role = value!;
                              });
                            },
                            activeColor: WNColors.blue,
                          ),
                        ],
                      ),
                    ),

                    if (selectedRole ==
                        null) // Show error message if no role selected
                      Padding(padding: const EdgeInsets.only(top: 8.0)),
                  ],
                ),
              ),
            ),
          ),

          // Fixed Next Button at the Bottom
          Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() &&
                      selectedRole != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                Page2PersonalDetails(userData: widget.userData),
                      ),
                    );
                  } else {
                    showWNMessage(context, isError: true, message: 'Please enter your name and select a role!');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: WNColors.blue,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Next',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
