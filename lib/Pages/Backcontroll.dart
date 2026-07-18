import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../login/branding.dart';

class BackButtonController extends GetxController {
  DateTime? _lastPressed;

  Future<bool> handleWillPop() async {
    DateTime now = DateTime.now();
    if (_lastPressed == null ||
        now.difference(_lastPressed!) > Duration(seconds: 2)) {
      _lastPressed = now;

      final context = Get.context;
      if (context != null) {
        showWNToast(context, 'Press back again to exit');
      }

      return false;
    }
    return true;
  }
}

class FullImagePage extends StatelessWidget {
  final String imageBase64;

  const FullImagePage({Key? key, required this.imageBase64}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Full Image')),
      body: Center(child: Image.memory(base64Decode(imageBase64))),
    );
  }
}
