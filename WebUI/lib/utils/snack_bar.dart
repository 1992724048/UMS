import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void showErrorSnack(BuildContext context, String message) {
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
