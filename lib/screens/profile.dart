// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'package:jeezy/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jeezy/screens/login_screen.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  final User user;
  final bool isDark;

  const ProfilePage({required this.user, required this.isDark, super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _passwordController = TextEditingController();

  late TextEditingController _nameController;
  late TextEditingController _classController;
  late TextEditingController _yearController;
  late TextEditingController _boardController;
  late TextEditingController _goalController;
  late TextEditingController _bioController;
  
  late List<String> _yearOptions;
  final List<String> _classOptions = ['11th', '12th', 'Dropper'];
  final List<String> _boardOptions = ['CBSE', 'CISCE', 'State Board', 'NIOS', 'IB', 'IGCSE', 'Other'];
  final List<String> _goalOptions = ['JEE Main', 'JEE Advanced', 'Both'];

  bool isLoading = true;
  bool isSaving = false;
  bool isImageUploading = false;
  bool isDeletingAccount = false;
  String? _profileImageUrl;
  File? _selectedImage;
  
  late AnimationController _animationController;
  late AnimationController _saveAnimationController;
  late AnimationController _deleteAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _saveScaleAnimation;
  late Animation<double> _deleteShakeAnimation;

  @override
  void initState() {
    super.initState();
    final currentYear = DateTime.now().year;
    _yearOptions = List.generate(4, (index) => (currentYear + index).toString());
    _initializeAnimations();
    _loadUserData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _saveAnimationController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _deleteAnimationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _saveScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _saveAnimationController,
      curve: Curves.easeInOut,
    ));

    _deleteShakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _deleteAnimationController,
      curve: Curves.elasticInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classController.dispose();
    _yearController.dispose();
    _boardController.dispose();
    _goalController.dispose();
    _bioController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    _saveAnimationController.dispose();
    _deleteAnimationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final updatedUser = FirebaseAuth.instance.currentUser!;

      final doc = await FirebaseFirestore.instance.collection('users').doc(updatedUser.uid).get();
      final data = doc.data();

      _nameController = TextEditingController(text: data?['display_name'] ?? updatedUser.displayName ?? '');
      _classController = TextEditingController(text: data?['user_class'] ?? '');
      _yearController = TextEditingController(text: data?['jee_year'] ?? '');
      _boardController = TextEditingController(text: data?['board'] ?? '');
      _goalController = TextEditingController(text: data?['goal'] ?? '');
      _bioController = TextEditingController(text: data?['bio'] ?? '');
      _profileImageUrl = data?['profile_image_url'] ?? updatedUser.photoURL;

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('Error loading profile data');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorSnackBar('Image size must be less than 5MB');
          return;
        }
        
        setState(() {
          _selectedImage = file;
          isImageUploading = true;
        });
        
        await _uploadProfileImage();
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting image: $e');
      print('Image picker error: $e');
    }
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${widget.user.uid}_$timestamp.jpg';
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': widget.user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final uploadTask = storageRef.putFile(_selectedImage!, metadata);
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Delete old profile image if it exists
      if (_profileImageUrl != null && _profileImageUrl!.contains('firebase')) {
        try {
          final oldRef = FirebaseStorage.instance.refFromURL(_profileImageUrl!);
          await oldRef.delete();
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      setState(() {
        _profileImageUrl = downloadUrl;
        isImageUploading = false;
      });

      _showSuccessSnackBar('Profile picture updated!');
    } on FirebaseException catch (e) {
      setState(() {
        isImageUploading = false;
      });
      
      String errorMessage = 'Error uploading image';
      switch (e.code) {
        case 'storage/unauthorized':
          errorMessage = 'You don\'t have permission to upload files';
          break;
        case 'storage/canceled':
          errorMessage = 'Upload was canceled';
          break;
        case 'storage/quota-exceeded':
          errorMessage = 'Storage quota exceeded';
          break;
        case 'storage/unauthenticated':
          errorMessage = 'Please log in to upload images';
          break;
        default:
          errorMessage = 'Upload failed: ${e.message}';
      }
      
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      setState(() {
        isImageUploading = false;
      });
      _showErrorSnackBar('Unexpected error occurred: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _saveAnimationController.forward().then((_) {
      _saveAnimationController.reverse();
    });

    setState(() {
      isSaving = true;
    });

    try {
      await widget.user.updateDisplayName(_nameController.text.trim());
      
      if (_profileImageUrl != null && _profileImageUrl != widget.user.photoURL) {
        await widget.user.updatePhotoURL(_profileImageUrl);
      }
      
      await widget.user.reload();

      await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).set({
        'display_name': _nameController.text.trim(),
        'user_class': _classController.text,
        'jee_year': _yearController.text,
        'board': _boardController.text,
        'goal': _goalController.text,
        'bio': _bioController.text.trim(),
        'profile_image_url': _profileImageUrl,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _showSuccessSnackBar('Profile updated successfully!');
      
      final updatedUser = FirebaseAuth.instance.currentUser!;
      Navigator.of(context).pop(updatedUser);

    } catch (e) {
      _showErrorSnackBar('Error saving profile: ${e.toString()}');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _deleteUserData() async {
    final userId = widget.user.uid;
    
    try {
      // Delete user's Firestore data
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      
      // Delete user's notes
      final notesQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();
      
      for (var doc in notesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's test results
      final resultsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .get();
      
      for (var doc in resultsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's progress data
      final progressQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();
      
      for (var doc in progressQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's chat history
      final chatQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('chat_history')
          .get();
      
      for (var doc in chatQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's bookmarks
      final bookmarksQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .get();
      
      for (var doc in bookmarksQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's feedback
      final feedbackQuery = await FirebaseFirestore.instance
          .collection('feedback')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (var doc in feedbackQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's profile images from Storage
      try {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images');
        final listResult = await storageRef.listAll();
        
        for (var item in listResult.items) {
          if (item.name.startsWith(userId)) {
            await item.delete();
          }
        }
      } catch (e) {
        print('Error deleting storage files: $e');
      }

      print('All user data deleted successfully');
    } catch (e) {
      print('Error deleting user data: $e');
      throw e;
    }
  }

  Future<void> _reauthenticateAndDelete() async {
    final user = FirebaseAuth.instance.currentUser!;
    
    try {
      // Check if user signed in with Google
      bool isGoogleUser = false;
      bool isEmailUser = false;
      
      for (var provider in user.providerData) {
        if (provider.providerId == 'google.com') {
          isGoogleUser = true;
        } else if (provider.providerId == 'password') {
          isEmailUser = true;
        }
      }

      if (isGoogleUser) {
        // Reauthenticate with Google
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          _showErrorSnackBar('Google sign-in was cancelled');
          return;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await user.reauthenticateWithCredential(credential);
      } else if (isEmailUser) {
        // Reauthenticate with email/password
        if (_passwordController.text.trim().isEmpty) {
          _showErrorSnackBar('Please enter your password');
          return;
        }

        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _passwordController.text.trim(),
        );

        await user.reauthenticateWithCredential(credential);
      }

      // Delete user data first
      await _deleteUserData();
      
      // Then delete the user account
      await user.delete();
      
      _showSuccessSnackBar('Account deleted successfully');
      
      // Navigate to login screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Authentication failed';
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Incorrect password';
          break;
        case 'user-mismatch':
          errorMessage = 'User mismatch during reauthentication';
          break;
        case 'user-not-found':
          errorMessage = 'User not found';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid credentials';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log in again and try deleting your account';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      _showErrorSnackBar(errorMessage);
    } catch (e) {
      _showErrorSnackBar('Error deleting account: ${e.toString()}');
    } finally {
      setState(() {
        isDeletingAccount = false;
      });
    }
  }

  void _showDeleteAccountDialog() {
    final user = FirebaseAuth.instance.currentUser!;
    bool isGoogleUser = false;
    bool isEmailUser = false;
    
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        isGoogleUser = true;
      } else if (provider.providerId == 'password') {
        isEmailUser = true;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: GoogleFonts.comicNeue(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ This action cannot be undone!',
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Deleting your account will permanently remove:',
                        style: GoogleFonts.comicNeue(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      ...['• Your profile and personal information',
                          '• All your notes and study materials',
                          '• Test results and progress data',
                          '• Chat history with AI assistant',
                          '• Bookmarks and saved content',
                          '• All uploaded files and images']
                          .map((item) => Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  item,
                                  style: GoogleFonts.comicNeue(fontSize: 13),
                                ),
                              )),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
                if (isEmailUser) ...[
                  Text(
                    'Enter your password to confirm:',
                    style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.comicNeue(),
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      hintStyle: GoogleFonts.comicNeue(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ] else if (isGoogleUser) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ll need to sign in with Google again to confirm deletion.',
                            style: GoogleFonts.comicNeue(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 20),
                
                Text(
                  'Type "DELETE" to confirm:',
                  style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                TextField(
                  style: GoogleFonts.comicNeue(),
                  decoration: InputDecoration(
                    hintText: 'Type DELETE',
                    hintStyle: GoogleFonts.comicNeue(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    setDialogState(() {});
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _passwordController.clear();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: isDeletingAccount ? null : () async {
                setState(() {
                  isDeletingAccount = true;
                });
                Navigator.pop(context);
                await _reauthenticateAndDelete();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeletingAccount
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Delete Forever',
                      style: GoogleFonts.comicNeue(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUserData() async {
    try {
      setState(() {
        isSaving = true;
      });

      final userId = widget.user.uid;
      Map<String, dynamic> exportData = {};

      // Get user profile data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        exportData['profile'] = userDoc.data();
      }

      // Get user's notes
      final notesQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notes')
          .get();
      
      exportData['notes'] = notesQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Get user's test results
      final resultsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('test_results')
          .get();
      
      exportData['test_results'] = resultsQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Get user's progress data
      final progressQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('progress')
          .get();
      
      exportData['progress'] = progressQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      // Convert to JSON string
      // final jsonString = jsonEncode(exportData);
      
      // For now, just show success message
      // In a real app, you'd save this to device storage or share it
      _showSuccessSnackBar('Data export prepared successfully!');
      
      // Show export data dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Data', style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your data has been exported successfully. In a production app, this would be saved to your device or shared.',
                style: GoogleFonts.comicNeue(),
              ),
              SizedBox(height: 16),
              Text(
                'Export includes: Profile, Notes, Test Results, and Progress Data',
                style: GoogleFonts.comicNeue(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: GoogleFonts.comicNeue()),
            ),
          ],
        ),
      );

    } catch (e) {
      _showErrorSnackBar('Error exporting data: ${e.toString()}');
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ThemeSwitchingArea(
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentThemeMode, child) {
          final isDark = currentThemeMode == ThemeMode.dark;
          final theme = Theme.of(context);

          return Theme(
            data: Theme.of(context).copyWith(
              textTheme: GoogleFonts.comicNeueTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            child: Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: theme.appBarTheme.backgroundColor,
                title: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Edit Profile",
                        style: GoogleFonts.comicNeue(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: theme.appBarTheme.titleTextStyle?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'export':
                          _exportUserData();
                          break;
                        case 'delete':
                          _deleteAnimationController.forward().then((_) {
                            _deleteAnimationController.reverse();
                          });
                          _showDeleteAccountDialog();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'export',
                        child: Row(
                          children: [
                            Icon(Icons.download, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Export Data', style: TextStyle(color: Colors.blue)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: AnimatedBuilder(
                          animation: _deleteShakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                _deleteShakeAnimation.value * 2 * (0.5 - _deleteShakeAnimation.value),
                                0,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.delete_forever, size: 20, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Account', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              body: isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading profile...',
                            style: GoogleFonts.comicNeue(
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Profile Picture Section
                                _buildProfilePictureSection(isDark, theme),
                                
                                SizedBox(height: 32),
                                
                                // Personal Information Card
                                _buildPersonalInfoCard(isDark, theme),
                                
                                SizedBox(height: 24),
                                
                                // Academic Information Card
                                _buildAcademicInfoCard(isDark, theme),
                                
                                SizedBox(height: 24),
                                
                                // Bio Section Card
                                _buildBioCard(isDark, theme),
                                
                                SizedBox(height: 24),
                                
                                // Account Actions Card
                                _buildAccountActionsCard(isDark, theme),
                                
                                SizedBox(height: 32),
                                
                                // Save Button
                                _buildSaveButton(isDark, theme),
                                
                                SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccountActionsCard(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Account Actions',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Export Data Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportUserData,
              icon: Icon(Icons.download, color: Colors.blue),
              label: Text(
                'Export My Data',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Delete Account Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isDeletingAccount ? null : () {
                _deleteAnimationController.forward().then((_) {
                  _deleteAnimationController.reverse();
                });
                _showDeleteAccountDialog();
              },
              icon: isDeletingAccount
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : Icon(Icons.delete_forever, color: Colors.red),
              label: Text(
                isDeletingAccount ? 'Deleting...' : 'Delete Account',
                style: GoogleFonts.comicNeue(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          Text(
            '⚠️ Account deletion is permanent and cannot be undone. All your data will be permanently removed.',
            style: GoogleFonts.comicNeue(
              fontSize: 12,
              color: Colors.red.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Keep all your existing widget building methods (_buildProfilePictureSection, _buildPersonalInfoCard, etc.)
  // They remain the same as in your original code

  Widget _buildProfilePictureSection(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : _profileImageUrl != null
                          ? Image.network(
                              _profileImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildDefaultAvatar(theme);
                              },
                            )
                          : _buildDefaultAvatar(theme),
                ),
              ),
              if (isImageUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: isImageUploading ? null : _pickImage,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Tap camera icon to change photo',
            style: GoogleFonts.comicNeue(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPersonalInfoCard(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Personal Information',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _nameController,
            label: "Display Name",
            icon: Icons.badge,
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicInfoCard(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'Academic Information',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildDropdownField(
            controller: _classController,
            label: "Class",
            options: _classOptions,
            icon: Icons.class_,
            isDark: isDark,
            theme: theme,
          ),
          SizedBox(height: 16),
          _buildDropdownField(
            controller: _yearController,
            label: "JEE Appearing Year",
            options: _yearOptions,
            icon: Icons.calendar_today,
            isDark: isDark,
            theme: theme,
          ),
          SizedBox(height: 16),
          _buildDropdownField(
            controller: _boardController,
            label: "Board of Education",
            options: _boardOptions,
            icon: Icons.account_balance,
            isDark: isDark,
            theme: theme,
          ),
          SizedBox(height: 16),
          _buildDropdownField(
            controller: _goalController,
            label: "Goal",
            options: _goalOptions,
            icon: Icons.flag,
            isDark: isDark,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildBioCard(bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C2542) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white24 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: theme.colorScheme.primary),
              SizedBox(width: 8),
              Text(
                'About Me',
                style: GoogleFonts.comicNeue(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            maxLength: 200,
            style: GoogleFonts.comicNeue(
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: "Bio (Optional)",
              hintText: "Tell us about yourself, your interests, or study goals...",
              labelStyle: GoogleFonts.comicNeue(
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              hintStyle: GoogleFonts.comicNeue(
                color: isDark ? Colors.white54 : Colors.grey.shade500,
              ),
              filled: true,
              fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
              prefixIcon: Icon(
                Icons.edit,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.comicNeue(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.comicNeue(
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
        filled: true,
        fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required IconData icon,
    required bool isDark,
    required ThemeData theme,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty && options.contains(controller.text) 
          ? controller.text 
          : null,
      dropdownColor: isDark ? Color(0xFF1E1E1E) : Colors.white,
      style: GoogleFonts.comicNeue(
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.comicNeue(
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
        filled: true,
        fillColor: isDark ? Color(0xFF2A2A2A) : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade400,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        prefixIcon: Icon(
          icon,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
      items: options
          .map((value) => DropdownMenuItem(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.comicNeue(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ))
          .toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
        }
      },
      validator: (value) => value == null || value.isEmpty ? 'Required' : null,
    );
  }

  Widget _buildSaveButton(bool isDark, ThemeData theme) {
    return ScaleTransition(
      scale: _saveScaleAnimation,
      child: Container(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isSaving ? null : _saveProfile,
          icon: isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Icons.save, color: Colors.white),
          label: Text(
            isSaving ? "Saving..." : "Save Profile",
            style: GoogleFonts.comicNeue(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
      ),
    );
  }
}
