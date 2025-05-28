// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final User user;
  final bool isDark;

  const ProfilePage({required this.user, required this.isDark, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _yearController;
  late TextEditingController _boardController;
  late List<String> _yearOptions;
  final List<String> _classOptions = ['11th', '12th', 'Dropper'];
  final List<String> _boardOptions = ['CBSE', 'CISCE', 'State Board', 'NIOS', 'IB', 'IGCSE', 'Other'];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _yearOptions = List.generate(3, (index) => (currentYear + index).toString());
    _loadUserData();
  }

  void _loadUserData() async {
    await FirebaseAuth.instance.currentUser?.reload();
    final updatedUser = FirebaseAuth.instance.currentUser!;

    final doc = await FirebaseFirestore.instance.collection('users').doc(updatedUser.uid).get();
    final data = doc.data();

    _nameController = TextEditingController(text: data?['display_name'] ?? updatedUser.displayName ?? '');
    _classController = TextEditingController(text: data?['user_class'] ?? '');
    _yearController = TextEditingController(text: data?['jee_year'] ?? '');
    _boardController = TextEditingController(text: data?['board'] ?? '');

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      await widget.user.updateDisplayName(_nameController.text);
      await widget.user.reload();
      final updatedUser = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'display_name': _nameController.text,
        'user_class': _classController.text,
        'jee_year': _yearController.text,
        'board': _boardController.text,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.of(context).pop(updatedUser);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated"),
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(Duration(seconds: 1));
      Navigator.of(context).pop();
      await Navigator.of(context).push(PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(),
          );
        },
        transitionDuration: Duration(milliseconds: 400),
      ));
      Navigator.pop(context, updatedUser);
    }
  }

  @override
  Widget build(BuildContext context) {

    final bool isDark = widget.isDark;

  final darkBackground = isDark ? Color.fromARGB(255, 12, 20, 41) : Colors.white;
  final cardColor = isDark ? Color.fromARGB(106, 39, 55, 84) : Colors.white;
  final fillColor = isDark ? Color(0xFF2A2A2A) : Colors.grey[200]!;
  final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade400;
  final textColor = isDark ? Colors.white : Colors.black87;
  final appBarColor = isDark ? Color(0xFF1C2542) : Colors.white;
  final appBarForegroundColor = isDark ? Colors.white : Colors.black87;
  final dropdownMenuColor = isDark ? Color(0xFF1E1E1E) : Color.fromARGB(255, 249, 248, 246);

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: GoogleFonts.comicNeueTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      child: Scaffold(
        backgroundColor: darkBackground,
        appBar: AppBar(
          title: Text("Edit Profile",
          style: TextStyle(fontWeight: FontWeight.bold ,fontFamily: GoogleFonts.comicNeue().fontFamily),),
          backgroundColor: appBarColor,
          foregroundColor: appBarForegroundColor,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: "Display Name",
                            fillColor: fillColor,
                            borderColor: borderColor,
                            textColor: textColor,
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            controller: _classController,
                            label: "Class",
                            options: _classOptions,
                            fillColor: fillColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            dropdownMenuColor: dropdownMenuColor,
                            style: GoogleFonts.comicNeue(),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            controller: _yearController,
                            label: "Appearing Year",
                            options: _yearOptions,
                            fillColor: fillColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            dropdownMenuColor: dropdownMenuColor,
                            style: GoogleFonts.comicNeue(),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownField(
                            controller: _boardController,
                            label: "Board of Education",
                            options: _boardOptions,
                            fillColor: fillColor,
                            borderColor: borderColor,
                            textColor: textColor,
                            dropdownMenuColor: dropdownMenuColor,
                            style: GoogleFonts.comicNeue(),
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.center, // Optional: to center horizontally
                            child: IntrinsicWidth( // 👈 Shrink to fit content
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minWidth: 120, // 👈 Set your max width
                                  maxHeight: 50
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.save),
                                  label: const Text("Save", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(184, 53, 61, 73),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],  
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required Color fillColor,
    required Color borderColor,
    required Color textColor,
    required Color dropdownMenuColor,
    required TextStyle style,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : null,
      dropdownColor: dropdownMenuColor,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      items: options
          .map((value) => DropdownMenuItem(
                value: value,
                child: Text(value, style: TextStyle(color: textColor)),
              ))
          .toList(),
      onChanged: (value) => controller.text = value!,
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }
}
