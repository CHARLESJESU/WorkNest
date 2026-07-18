import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// WorkNest brand colors, shared across login/signup/forgot-password screens.
class WNColors {
  static const navy = Color(0xFF0A1748);
  static const navyDeep = Color(0xFF060F30);
  static const blue = Color(0xFF1E6FF0);
  static const orange = Color(0xFFFF7A1A);
  static const bg = Color(0xFFF6F8FC);
}

/// Profile avatar: renders a base64-encoded image if present, else initials.
/// Never use FileImage(File(path)) for profile pictures — local picker paths
/// don't survive across sessions/devices, which is why avatars used to go blank.
class WNAvatar extends StatelessWidget {
  final String? imageBase64;
  final String name;
  final double radius;

  const WNAvatar({super.key, required this.imageBase64, required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    Uint8List? bytes;
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      try {
        bytes = base64Decode(imageBase64!);
      } catch (_) {
        bytes = null;
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: WNColors.blue.withOpacity(0.1),
      backgroundImage: bytes != null ? MemoryImage(bytes) : null,
      child: bytes == null
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(fontSize: radius, color: WNColors.blue, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}

/// Compresses a picked image file and returns it as a base64 string, so
/// profile pictures survive across sessions/devices via Firestore instead
/// of relying on a local file path that only exists on the device that
/// picked it.
Future<String?> compressImageToBase64(String imagePath) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final targetPath = path.join(
      tempDir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final compressed = await FlutterImageCompress.compressAndGetFile(
      imagePath,
      targetPath,
      quality: 50,
      minWidth: 300,
      minHeight: 300,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) return null;
    final bytes = await File(compressed.path).readAsBytes();
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}

/// Branded replacement for SnackBar — a small modal dialog with an icon,
/// message, and single OK action. Use everywhere instead of ScaffoldMessenger.
Future<void> showWNMessage(
  BuildContext context, {
  required String message,
  String? title,
  bool isError = false,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  return showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isError ? Colors.red : WNColors.blue).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isError ? Icons.error_outline : Icons.check_circle,
                color: isError ? Colors.red : WNColors.blue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title ?? (isError ? "Something went wrong" : "Done"),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: WNColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            if (actionLabel != null && onAction != null)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: WNColors.blue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Dismiss", style: TextStyle(color: WNColors.blue, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onAction();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: WNColors.blue,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(actionLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: WNColors.blue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Lightweight self-dismissing toast — for transient hints (e.g. "press back
/// again to exit") where a blocking dialog would get in the way. Not a
/// SnackBar: no ScaffoldMessenger/Scaffold dependency, just an Overlay entry.
void showWNToast(BuildContext context, String message, {Duration duration = const Duration(seconds: 2)}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: WNColors.navy,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () => entry.remove());
}

/// In-app logo (login/signup/forgot-password headers).
class WNLogo extends StatelessWidget {
  final double size;
  const WNLogo({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/appinsidelogo.png",
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
