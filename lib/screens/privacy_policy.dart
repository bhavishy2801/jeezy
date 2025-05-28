// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({Key? key}) : super(key: key);

  Text _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        height: 2,
      ),
    );
  }

  Text _buildBodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Privacy Policy")),
      body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: DefaultTextStyle(  
        style: TextStyle(
          fontFamily: GoogleFonts.comicNeue().fontFamily,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const Text(
            "Privacy Policy for JEEzy",
            style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Effective Date: May 24, 2025",
            style: TextStyle(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),

          _buildBodyText(
            "Thank you for using JEEzy. Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your information.",
          ),

          _buildSectionTitle("1. Information We Collect"),
          _buildBodyText(
            "• Personal Information: We collect your name, email, class, board, and JEE appearing year during signup or profile editing.\n"
            "• Feedback Data: If you choose to send us feedback, the data you submit is used solely to improve the app.\n"
            "• Mentor Responses: When using the AI Mentor feature, your test/survey responses are processed securely to generate personalized preparation strategies.",
          ),

          _buildSectionTitle("2. How We Use Your Information"),
          _buildBodyText(
            "• To personalize your app experience and recommendations.\n"
            "• To provide and improve our AI Mentor functionality.\n"
            "• To respond to your feedback and support queries.\n"
            "• To store and sync your data using Firebase Firestore.",
          ),

          _buildSectionTitle("3. Data Sharing and Storage"),
          _buildBodyText(
            "• We do not sell or share your personal data with third-party advertisers.\n"
            "• Your data is securely stored in Google Firebase services.\n"
            "• Aggregated, anonymized data may be used to improve AI performance.",
          ),

          _buildSectionTitle("4. Data Security"),
          _buildBodyText(
            "• We use industry-standard measures, including secure connections and authentication via Firebase, to protect your information.\n"
            "• Your data is only accessible to authorized services and personnel.",
          ),

          _buildSectionTitle("5. Your Choices"),
          _buildBodyText(
            "• You can update or delete your profile data anytime from the app.\n"
            "• You can choose not to use the AI Mentor feature.",
          ),

          _buildSectionTitle("6. Changes to this Policy"),
          _buildBodyText(
            "We may update this policy from time to time. Any changes will be reflected on this page with an updated effective date.",
          ),

          _buildSectionTitle("7. Contact Us"),
          _buildBodyText(
            "If you have questions or concerns about this Privacy Policy, feel free to contact us at:\n\n"
            "bhavishyrocker2801@gmail.com",
          ),

          const SizedBox(height: 32),
          const Center(
            child: Text(
            "By using JEEzy, you agree to the collection and use of your information in accordance with this policy.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
            ),
            ),
          ),
          const SizedBox(height: 32),
          ],
        ),
        ),
      ),
      ),
    );
  }
}
