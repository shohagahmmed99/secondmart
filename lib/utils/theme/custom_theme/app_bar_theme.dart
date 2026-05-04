import 'package:flutter/material.dart';

final AppBarTheme appBarTheme = AppBarTheme(
  // Background color of AppBar
  backgroundColor: Color(0xFF34495E),

  // Text style of the title
  titleTextStyle: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  ),

  // Icon color (back button, action icons)
  iconTheme: IconThemeData(color: Colors.white, size: 24),

  // Elevation (shadow)
  elevation: 4,

  // Center title? true for iOS style
  centerTitle: false,
);
