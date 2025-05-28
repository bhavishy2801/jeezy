// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';

class BookmarksPage extends StatelessWidget {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("My Bookmarks")),
      body: Center(child: Text("No bookmarks yet. Add some from Notes!")),
    );
  }
}