import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nivetha123/screens/jobprovider/jobprovider_home.dart';
import 'package:nivetha123/screens/worker/worker_home.dart';
import 'package:nivetha123/models/user_data.dart';
import '../../theme/branding.dart';

class CheckboxAnimationPage extends StatefulWidget {
  final bool success;
  final UserData? userData;

  const CheckboxAnimationPage({Key? key, required this.success, this.userData})
    : super(key: key);

  @override
  _CheckboxAnimationPageState createState() => _CheckboxAnimationPageState();
}

class _CheckboxAnimationPageState extends State<CheckboxAnimationPage> {
  bool isChecked = false;

  @override
  void initState() {
    super.initState();

    // Run the animation and navigate only if registration was successful
    if (widget.success) {
      _runAnimationAndNavigate();
    }
  }

  // A helper method to handle animation and navigation logic
  Future<void> _runAnimationAndNavigate() async {
    // Trigger the checkbox animation
    setState(() {
      isChecked = true;
    });

    // Wait for the animation to complete before navigating
    await Future.delayed(const Duration(seconds: 1));

    if (widget.userData != null) {
      final prefs = await SharedPreferences.getInstance();
      // Store user data as a JSON string in shared preferences
      await prefs.setString('userData', jsonEncode(widget.userData!.toJson()));

      // Navigate based on user role (Worker or Job Provider)
      Widget nextPage =
          widget.userData!.role == 'Worker'
              ? Workerpage(userData: widget.userData!)
              : Jobproviderpage(userData: widget.userData!);

      // Replace the current screen with the appropriate page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated container for checkbox effect
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: isChecked ? 150 : 70,
              height: isChecked ? 150 : 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isChecked ? WNColors.blue : Colors.grey[300],
              ),
              child:
                  isChecked
                      ? const Icon(Icons.check, size: 100, color: Colors.white)
                      : const SizedBox.shrink(),
            ),
            const SizedBox(height: 30),
            // Display appropriate success message
            Text(
              widget.success
                  ? "Registration Successful!"
                  : "Please accept the Terms & Conditions.",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: WNColors.navy,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // If registration wasn't successful, show a "Go Back" button
            if (!widget.success)
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: WNColors.blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Go Back"),
              ),
          ],
        ),
      ),
    );
  }
}
