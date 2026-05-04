import 'package:flutter/material.dart';

final ElevatedButtonThemeData appElevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    // Button size & padding
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: Size(64, 48),

    // Shape (rounded corners)
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

    // Colors
    backgroundColor: Color(0xFF3498DB), // Primary button color
    disabledBackgroundColor: Colors.grey,
    disabledForegroundColor: Colors.grey,
    foregroundColor: Colors.white, // Text color
    // Text style
    textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),

    // Elevation (shadow)
    elevation: 4,
  ),
);
