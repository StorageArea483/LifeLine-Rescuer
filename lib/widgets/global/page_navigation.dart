import 'package:flutter/material.dart';

void pageNavigation(Widget destination, BuildContext context) {
  if (context.mounted) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (context) => destination));
  }
}
