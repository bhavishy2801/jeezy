// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Tests Screen!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}