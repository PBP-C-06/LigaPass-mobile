import 'package:flutter/material.dart';

/// Helper untuk menampilkan snackbar konsisten.
class SnackbarHelper {
  const SnackbarHelper._();

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
      ),
    );
  }
}
