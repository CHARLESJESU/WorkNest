import 'package:flutter/material.dart';
import 'package:nivetha123/screens/personal_details.dart';
import 'package:nivetha123/screens/user_data.dart';
import '../widgets/step_progress.dart';

class Page1NameRole extends StatefulWidget {
  final UserData userData;
  Page1NameRole({required this.userData});

  @override
  _Page1NameRoleState createState() => _Page1NameRoleState();
}

class _Page1NameRoleState extends State<Page1NameRole> {
  final _formKey = GlobalKey<FormState>();
  String? selectedRole; // Store the selected role separately for validation
  bool _submitted = false; // Track if the user tried to submit

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
              'User Profile',
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StepProgress(currentStep: 1, totalSteps: 5),
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
                              'What Should We Call You?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: Color(0xFF2563EB),
                                ),
                                hintText: 'Your Name',
                                hintStyle: TextStyle(color: Colors.grey[500]),
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
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Name is required'
                                          : null,
                              onChanged:
                                  (value) => widget.userData.name = value,
                            ),
                            SizedBox(height: 32),
                            Text(
                              'What is your role?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            SizedBox(height: 12),
                            Column(
                              children: [
                                RadioListTile<String>(
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.handyman,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Worker',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  value: 'Worker',
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value;
                                      widget.userData.role = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                RadioListTile<String>(
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.business_center,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Job Provider',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  value: 'Job Provider',
                                  groupValue: selectedRole,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedRole = value;
                                      widget.userData.role = value!;
                                    });
                                  },
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ],
                            ),
                            if (selectedRole == null && _submitted)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Please select a role',
                                  style: TextStyle(
                                    color: Colors.red[700],
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
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _submitted = true;
                  });

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
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Color(0xFF2563EB).withOpacity(0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
