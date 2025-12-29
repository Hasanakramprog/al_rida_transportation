import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Simple script to generate a basic app icon with a bus icon
/// Run this with: flutter run -t lib/generate_icon.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create a simple icon with Material Icons bus
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Background
  final paint = Paint()..color = const Color(0xFF2196F3);
  canvas.drawRect(const Rect.fromLTWH(0, 0, 1024, 1024), paint);

  // Draw white bus icon (simplified)
  final iconPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  // Simple bus shape
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(256, 256, 512, 512),
      const Radius.circular(40),
    ),
    iconPaint,
  );

  // Windows
  final windowPaint = Paint()
    ..color = const Color(0xFF1976D2)
    ..style = PaintingStyle.fill;

  canvas.drawRect(const Rect.fromLTWH(300, 320, 180, 160), windowPaint);
  canvas.drawRect(const Rect.fromLTWH(544, 320, 180, 160), windowPaint);

  // Wheels
  final wheelPaint = Paint()
    ..color = const Color(0xFF424242)
    ..style = PaintingStyle.fill;

  canvas.drawCircle(const Offset(356, 720), 48, wheelPaint);
  canvas.drawCircle(const Offset(668, 720), 48, wheelPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  if (byteData != null) {
    final file = File('assets/icon/app_icon.png');
    await file.writeAsBytes(byteData.buffer.asUint8List());
    print('Icon generated successfully at: ${file.path}');
  }
}
