import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final VoidCallback onNoteUpdated;

  const NoteDetailScreen({
    Key? key,
    required this.note,
    required this.onNoteUpdated,
  }) : super(key: key);

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note['title']);
    _contentController = TextEditingController(text: widget.note['content']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Note' : 'Note Details',
          style: GoogleFonts.comicNeue(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: _isSaving ? CircularProgressIndicator() : Icon(Icons.save),
              onPressed: _isSaving ? null : _saveNote,
            )
          else
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing)
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                style: GoogleFonts.comicNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                widget.note['title'],
                style: GoogleFonts.comicNeue(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            SizedBox(height: 16),
            
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.note['subject'],
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.note['category'],
                    style: GoogleFonts.comicNeue(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Created: ${_formatDate(widget.note['createdAt'])}',
              style: GoogleFonts.comicNeue(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            
            SizedBox(height: 16),
            
            Expanded(
              child: _isEditing
                  ? TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      style: GoogleFonts.comicNeue(),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        widget.note['content'],
                        style: GoogleFonts.comicNeue(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      
      if (title.isEmpty || content.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Title and content cannot be empty')),
        );
        return;
      }

      final wordCount = content.split(' ').length;
      final readingTime = (wordCount / 200).ceil();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .doc(widget.note['id'])
          .update({
        'title': title,
        'content': content,
        'wordCount': wordCount,
        'readingTime': readingTime,
        'updatedAt': Timestamp.now(),
      });

      widget.onNoteUpdated();
      
      setState(() {
        _isEditing = false;
        _isSaving = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Note updated successfully')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating note: $e')),
      );
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy at hh:mm a').format(date);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
