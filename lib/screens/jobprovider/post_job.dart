import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/branding.dart';


class FormPage extends StatefulWidget {
  final String userId;

  FormPage({required this.userId});

  @override
  _FormPageState createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  File? _imageFile;
  final TextEditingController _descriptionController = TextEditingController();
  final CollectionReference _jobCollection = FirebaseFirestore.instance
      .collection('jobs')
      .doc('workers')
      .collection('workers');

  bool _isUploading = false;

  bool _showSuccessAnimation = false;
  String _generatedOrderId = '';

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }


  Future<String?> compressAndConvertToBase64(String imagePath) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        imagePath,
        targetPath,
        quality: 40,
        format: CompressFormat.jpeg,
      );

      // Validate compression result
      if (compressedFile == null || !await File(compressedFile.path).exists()) {
        if (mounted) showWNMessage(context, isError: true, message: "Image compression failed.");
        return null;
      }

      // Read compressed image as bytes and encode to base64
      final bytes = await compressedFile.readAsBytes();
      print("Compressed size: ${bytes.length} bytes");
      return base64Encode(bytes);
    } catch (e) {
      print("Compression or conversion failed: $e");
      return null;
    }
  }


  String _generateOrderId() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    final id =
    List.generate(7, (index) => chars[rand.nextInt(chars.length)]).join();
    return id; // just the random string, no prefix here
  }

  Future<void> _uploadOrder() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showWNMessage(context, isError: true, message: "User not logged in");
      return;
    }

    if (_imageFile == null || _descriptionController.text.isEmpty) {
      showWNMessage(context, isError: true, message: "Please select an image and enter a description");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final userId = widget.userId;
      print(_imageFile);

      final base64Image = await compressAndConvertToBase64(_imageFile!.path);
      print(base64Image);

      final rawOrderId = _generateOrderId();
      final orderKey = 'OID_$rawOrderId';

      final userDocRef = FirebaseFirestore.instance
          .collection('jobs')
          .doc('workers')
          .collection('workers')
          .doc(userId);

// ✅ First, set a field in the user doc
      await userDocRef.set(
          {'summa': 1}, SetOptions(merge: true)); // merge to avoid overwrite

// ✅ Then, add order to the subcollection
      await userDocRef
          .collection('order')
          .doc(orderKey)
          .set({
        'orderkey': orderKey,
        'description': _descriptionController.text,
        'imageBase64': base64Image,
      });

      setState(() {
        _showSuccessAnimation = true;
        _generatedOrderId = orderKey;
      });

      Future.delayed(Duration(seconds: 3), () {
        if (mounted) Navigator.of(context).pop();
      });
    }catch (e) {
      if (mounted) showWNMessage(context, isError: true, message: "Failed to post job: $e");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }


  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WNColors.bg,
      appBar: AppBar(
        title: const Text(
          "Post Job",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: WNColors.blue,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WNColors.navy),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: TextField(
                      controller: _descriptionController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Type your description...',
                        hintStyle: const TextStyle(color: Colors.black38),
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
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Photo",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: WNColors.navy),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(
                              _imageFile!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add_a_photo_outlined, size: 36, color: WNColors.blue),
                                  SizedBox(height: 8),
                                  Text("Tap to select an image", style: TextStyle(color: Colors.black54, fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WNColors.blue,
                        disabledBackgroundColor: WNColors.blue.withOpacity(0.7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              "Post Job",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          if (_showSuccessAnimation)
            Center(
              child: AnimatedOpacity(
                duration: Duration(milliseconds: 500),
                opacity: _showSuccessAnimation ? 1.0 : 0.0,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: WNColors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle, color: WNColors.blue, size: 44),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Job posted successfully!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: WNColors.navy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Order ID: $_generatedOrderId",
                        style: const TextStyle(fontSize: 14, color: Colors.black54),
                      ),
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
