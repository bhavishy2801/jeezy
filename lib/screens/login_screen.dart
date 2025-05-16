import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jeezy/screens/home_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jeezy/screens/first_time.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _verificationId = '';
  bool _isOtpDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadySignedIn(); // Auto-login if user exists
  }

      Future<void> _checkAlreadySignedIn() async {
      final User? user = _auth.currentUser;
      if (user != null) {
        print('User already signed in: ${user.uid}');
        await _navigateAfterLogin(user);  // Important: call this method, not just navigate directly
      } else {
        print('No user signed in yet.');
      }
    }


  Future<void> _handleGoogleAuth() async {
    try {
      await _googleSignIn.signOut(); // force account picker
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null && mounted) {
        print('Google sign-in successful: ${user.uid}');
        await _navigateAfterLogin(user);
      }
    } catch (e) {
      print("Google Sign-In Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed")),
      );
    }
  }

  void _showPhoneInputDialog() {
    TextEditingController phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Phone Login"),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: "+91XXXXXXXXXX",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _verifyPhoneNumber(phoneController.text.trim());
              },
              child: Text("Send OTP"),
            ),
          ],
        );
      },
    );
  }

      Future<void> _navigateAfterLogin(User user) async {
        print('Checking Firestore document for user: ${user.uid}');

        final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await userDoc.get();

        if (!docSnapshot.exists) {
          print('User doc does not exist, creating...');
          await userDoc.set({'created_at': FieldValue.serverTimestamp()});
        } else {
          print('User doc exists');
        }

        final updatedDoc = await userDoc.get();
        final data = updatedDoc.data();

        print('User data from Firestore: $data');

        if (data == null || !data.containsKey('user_class') || !data.containsKey('jee_year')) {
          print('User profile incomplete, going to FirstTimeSetup');
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => FirstTimeSetup()),
          );
        } else {
          print('User profile complete, going to HomePage');
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage(user: user)),
          );
        }
      }



  Future<void> _verifyPhoneNumber(String phoneNumber) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-sign in on Android sometimes
          await _auth.signInWithCredential(credential);
          final user = _auth.currentUser;
          if (user != null && mounted) {
            await _navigateAfterLogin(user);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification failed: ${e.message}")),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _showOtpDialog();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      print("Phone verification error: $e");
    }
  }

  void _showOtpDialog() {
    if (_isOtpDialogOpen) return; // prevent multiple dialogs
    _isOtpDialogOpen = true;

    TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter OTP"),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: "6-digit OTP"),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final smsCode = otpController.text.trim();
                final credential = PhoneAuthProvider.credential(
                  verificationId: _verificationId,
                  smsCode: smsCode,
                );

                try {
                  await _auth.signInWithCredential(credential);
                  final user = _auth.currentUser;
                  if (user != null && mounted) {
                    Navigator.pop(context); // close OTP dialog
                    await _navigateAfterLogin(user);
                  }
                } catch (e) {
                  print("OTP Sign-in Error: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid OTP")),
                  );
                }
              },
              child: Text("Verify"),
            ),
          ],
        );
      },
    ).then((_) {
      _isOtpDialogOpen = false; // reset after dialog closes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Colors.grey.shade900, // Set a background color if needed
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                Image.asset(
                  'assets/images/login_dark.png',
                  width: 300,
                ),
                Text(
                  "Welcome to JEEzy",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: GoogleFonts.comicNeue().fontFamily,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Add color since AppBar is removed
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _handleGoogleAuth,
                  icon: Icon(Icons.login, color: Colors.white),
                  label: Text(
                    "Sign in with Google",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(35, 211, 235, 236),
                  ),
                ),
                SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showPhoneInputDialog,
                  icon: Icon(Icons.phone, color: Colors.white), 
                  label: Text(
                    "Sign in with Phone",
                    style: TextStyle(
                      fontFamily: GoogleFonts.comicNeue().fontFamily,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(35, 211, 235, 236),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  }
}
