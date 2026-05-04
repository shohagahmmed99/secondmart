import 'package:flutter/material.dart';

final InputDecorationTheme appInputDecorationTheme = InputDecorationTheme(
  // Border when text field is enabled but not focused
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Color(0xFF34495E), width: 1.5),
  ),

  // Border when text field is focused
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Color(0xFF34495E), width: 2),
  ),

  // Border when error occurs
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.red, width: 1.5),
  ),

  // Border when focused & error
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: Colors.red, width: 2),
  ),

  // Hint text style
  hintStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Colors.grey[500],
  ),

  // Label text style
  labelStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: Color(0xFF34495E),
  ),

  // Content padding inside the text field
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),

  // Fill color for filled text fields
  filled: true,
  fillColor: Colors.grey[100],

  // Error style
  errorStyle: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: Colors.red,
  ),
);
