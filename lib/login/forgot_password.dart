import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'branding.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool emailExists = false;
  bool isCheckingEmail = false;
  bool isSendingReset = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> checkEmail() async {
    String email = emailController.text;
    setState(() => isCheckingEmail = true);

    // Check if the email exists in Firestore
    final userQuery = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    if (userQuery.docs.isNotEmpty) {
      setState(() {
        emailExists = true;
        isCheckingEmail = false;
      });
    } else {
      setState(() => isCheckingEmail = false);
      _showErrorDialog("Your email ID does not exist. Go to Sign Up.");
    }
  }

  void resetPassword() async {
    if (_formKey.currentState!.validate()) {
      String email = emailController.text;
      setState(() => isSendingReset = true);

      try {
        // Send a password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        _showSuccessDialog("Password reset email has been sent. Please check your inbox.");
      } catch (e) {
        _showErrorDialog("An error occurred while sending the email.");
      }

      setState(() => isSendingReset = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: WNColors.navy),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: WNLogo(size: 110)),
                  const SizedBox(height: 24),
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: WNColors.navy,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Enter your registered email address and we will send you a password reset link.",
                    style: TextStyle(fontSize: 15, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: emailController,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Email Address",
                      hintStyle: const TextStyle(color: Colors.black45, fontSize: 16),
                      prefixIcon: const Icon(Icons.email_outlined, color: WNColors.blue),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isCheckingEmail ? null : checkEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WNColors.blue,
                        disabledBackgroundColor: WNColors.blue.withOpacity(0.7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isCheckingEmail
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Check Email",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),
                  if (emailExists) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSendingReset ? null : resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WNColors.blue,
                          disabledBackgroundColor: WNColors.blue.withOpacity(0.7),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isSendingReset
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                "Send Reset Email",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
