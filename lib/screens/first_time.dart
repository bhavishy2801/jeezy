import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirstTimeSetup extends StatefulWidget {
  @override
  State<FirstTimeSetup> createState() => _FirstTimeSetupState();
}

class _FirstTimeSetupState extends State<FirstTimeSetup> {
  String? selectedClass;
  String? selectedYear;
  final TextEditingController _nameController = TextEditingController();

  final List<String> classes = ['11th', '12th', 'Dropper'];
  final List<String> years = List.generate(3, (index) {
    final year = DateTime.now().year + index;
    return year.toString();
  });

  final _formKey = GlobalKey<FormState>();
  bool _isDataSaved = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    if (!_isDataSaved) {
      FirebaseAuth.instance.signOut();
    }
    super.dispose();
  }

  Future<void> saveUserInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await user.updateDisplayName(_nameController.text);
          await user.reload();

          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'display_name': _nameController.text,
            'user_class': selectedClass,
            'jee_year': selectedYear,
          }, SetOptions(merge: true));

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isProfileComplete', true);

          setState(() => _isDataSaved = true);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => HomePage(user: user)),
          );
        } catch (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving profile: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Color(0xFF121212),
        title: Text(
          "Complete Your Profile",
          style: TextStyle(
            fontFamily: GoogleFonts.comicNeue().fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Your Name",
                          labelStyle: TextStyle(color: Color.fromARGB(132, 255, 255, 255)),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.blue),
                          ),
                        ),
                        validator: (val) => val == null || val.isEmpty
                            ? "Please enter your name"
                            : null,
                      ),
                      SizedBox(height: 30),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select your class",
                          labelStyle: TextStyle(color: Color.fromARGB(132, 255, 255, 255)),
                        ),
                        dropdownColor: Color(0xFF1E1E1E),
                        style: TextStyle(color: Colors.white),
                        items: classes
                            .map((cls) => DropdownMenuItem(
                                  value: cls,
                                  child: Text(cls),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedClass = val),
                        validator: (val) => val == null ? "Please select your class" : null,
                      ),
                      SizedBox(height: 30),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select JEE appearing year",
                          labelStyle: TextStyle(color: Color.fromARGB(132, 255, 255, 255)),
                        ),
                        dropdownColor: Color(0xFF1E1E1E),
                        style: TextStyle(color: Colors.white),
                        items: years
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text(year),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedYear = val),
                        validator: (val) => val == null ? "Please select your JEE year" : null,
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                          backgroundColor: Colors.blueAccent,
                        ),
                        onPressed: saveUserInfo,
                        child: Text(
                          "Save & Continue",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 30),
                      Image.asset(
                        'assets/images/student.png',
                        height: 200,
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}