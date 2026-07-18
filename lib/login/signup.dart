import 'package:flutter/material.dart';

import '../authendication/authentication.dart';
import 'Login.dart';
import 'branding.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _isPasswordVisible = false;
  bool _signupSuccess = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUpUser() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isLoading = true);

      String res = await AuthServicews().signupUser(
        email: emailController.text,
        password: passwordController.text,
        name: nameController.text,
      );

      setState(() => isLoading = false);

      if (res == "success") {
        setState(() => _signupSuccess = true);
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        _showErrorDialog(res);
      }
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPass = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: isPass ? !_isPasswordVisible : false,
        style: const TextStyle(fontSize: 18),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please fill this field';
          }
          if (hintText == 'Enter your email' &&
              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'Invalid email address';
          }
          if (hintText == 'Enter your password' && !isValidPassword(value)) {
            return 'Password must include at least 1 letter, 1 number, and 1 special character.';
          }
          return null;
        },
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: WNColors.blue),
          suffixIcon: isPass
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: WNColors.blue,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          )
              : null,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
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
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  bool isValidPassword(String password) {
    return RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[@$!%*?&_])[A-Za-z\d@$!%*?&_]{8,}$')
        .hasMatch(password);
  }

  Widget _buildButton({
    required VoidCallback? onTap,
    required String text,
    bool loading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: WNColors.blue,
          disabledBackgroundColor: WNColors.blue.withOpacity(0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        ),
        child: loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: WNColors.bg,
      body: SafeArea(
        child: _signupSuccess ? _buildSuccessView() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: WNColors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: WNColors.blue, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              "Account Created!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: WNColors.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              "Your account has been created successfully. Taking you to login…",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: WNColors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Center(child: WNLogo(size: 120)),
                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Create Your Account",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: WNColors.navy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: nameController,
                    hintText: 'Enter your name',
                    icon: Icons.person,
                  ),
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Enter your email',
                    icon: Icons.email,
                  ),
                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Enter your password',
                    icon: Icons.lock,
                    isPass: true,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: _buildButton(
                      onTap: isLoading ? null : signUpUser,
                      text: "Sign Up",
                      loading: isLoading,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          ),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: WNColors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
