// ignore_for_file: use_super_parameters, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedCategory;
  // ignore: unused_field
  String _userEmail = "";

  final List<String> _categories = [
    "Bug Report",
    "Feature Request",
    "General Feedback",
    "Other"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  Future<void> _loadUserEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() {
        _userEmail = snapshot.data()?['email'] ?? user.email ?? "Unknown";
      });
    }
  }

  Future<void> _sendFeedback() async {
    if (_formKey.currentState!.validate()) {
      final Uri emailUri = Uri.parse(
        'mailto:bhavishyrocker2801@gmail.com?subject=${Uri.encodeComponent("Jeezy App Feedback\n${_selectedCategory ?? 'General'}")}&body=${Uri.encodeComponent("${_feedbackController.text}\n\nRegards\n${_nameController.text.isEmpty ? "Anonymous" : _nameController.text}")}'
      );
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Send Feedback", style: GoogleFonts.comicNeue(fontWeight: FontWeight.w500),)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Your Name (optional)", style: GoogleFonts.comicNeue(fontSize: 16),),
              TextFormField(
                style: GoogleFonts.comicNeue(fontSize: 16),
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Enter your name",
                ),
              ),
              SizedBox(height: 30),
              Text("Feedback Category (optional)", style: GoogleFonts.comicNeue(fontSize: 16),),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: Text("Select Category", style: GoogleFonts.comicNeue(fontSize: 16),),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: GoogleFonts.comicNeue(fontSize: 16),),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              SizedBox(height: 30),
              Text("Feedback (required)", style: GoogleFonts.comicNeue(fontSize: 16),),
              TextFormField(
                style: GoogleFonts.comicNeue(fontSize: 16),
                controller: _feedbackController,
                decoration: InputDecoration(
                  errorStyle: GoogleFonts.comicNeue(fontSize: 13),
                  hintText: "Enter your feedback",
                ),
                maxLines: 5,
                validator: (value) {
                  
                  if (value == null || value.trim().isEmpty) {
                    return "Feedback is required";
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _sendFeedback,
                icon: Icon(Icons.send),
                label: Text("Send Feedback via Email", style: GoogleFonts.comicNeue(fontSize: 16, fontWeight: FontWeight.bold),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
