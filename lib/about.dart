import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: key,
      child: Text(
        'About Page - Details about the application and team',
        style: TextStyle(fontSize: 24, color: Colors.white),
      ),
    );
  }
}
