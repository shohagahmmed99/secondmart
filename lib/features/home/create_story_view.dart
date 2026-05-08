import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:second_mart/utils/cloudinary_service.dart';

class CreateStoryView extends StatefulWidget {
  const CreateStoryView({super.key});

  @override
  State<CreateStoryView> createState() => _CreateStoryViewState();
}

class _CreateStoryViewState extends State<CreateStoryView> {
  XFile? _pickedImage;
  bool _isLoading = false;
  String _status = '';

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  Future<void> _uploadStory() async {
    if (_pickedImage == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Uploading story...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Upload to Cloudinary
      final imageUrl = await CloudinaryService.uploadImage(_pickedImage!.path);

      // Save to Firebase Realtime Database
      final storyRef = FirebaseDatabase.instance.ref('stories').push();
      await storyRef.set({
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'userPic': user.photoURL,
        'storyImage': imageUrl,
        'createdAt': ServerValue.timestamp,
        // Story expires in 24 hours
        'expiresAt': DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story posted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting story: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _status = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Create Story', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_pickedImage != null)
            TextButton(
              onPressed: _isLoading ? null : _uploadStory,
              child: _isLoading 
                ? SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onSurface, strokeWidth: 2)
                  )
                : const Text('Share', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Center(
        child: _pickedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_library, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    child: const Text('Select Photo'),
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(_pickedImage!.path), fit: BoxFit.contain),
                  if (_isLoading)
                    Container(
                      color: Colors.black45,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Colors.blue),
                            const SizedBox(height: 16),
                            Text(_status, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
