import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:jeezy/screens/first_time.dart';


class LoadingDecider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Not logged in"));
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data;

        if (userData == null ||
            !userData.exists ||
            userData.data() == null ||
            !(userData.data() as Map).containsKey('user_class') ||
            !(userData.data() as Map).containsKey('jee_year')) {

          return FirstTimeSetup();
        }
        
        return HomePage(user: user);
      },
    );
  }
}