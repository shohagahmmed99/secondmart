import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:second_mart/utils/cloudinary_service.dart';

class SellView extends StatefulWidget {
  const SellView({super.key});

  @override
  State<SellView> createState() => _SellViewState();
}

class _SellViewState extends State<SellView> {
  // Image picker state
  final List<XFile> _pickedImages = [];
  static const int _maxImages = 10;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _conditionController = TextEditingController();
  final _contactInfoController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String _uploadStatus = '';
  double _uploadProgress = 0.0;

  String? _selectedCategory;
  final List<String> _categories = [
    'Electronics',
    'Vehicles',
    'Property',
    'Home & Garden',
    'Fashion',
    'Hobbies & Leisure',
    "Others",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _conditionController.dispose();
    _contactInfoController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Picks images and appends them to the list (respects [_maxImages] cap).
  Future<void> _pickImages() async {
    if (_pickedImages.length >= _maxImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Maximum $_maxImages photos allowed')),
        );
      }
      return;
    }

    final int remaining = _maxImages - _pickedImages.length;

    if (Platform.isWindows) {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.image,
      );
      if (result != null && result.files.isNotEmpty) {
        final newFiles = result.files
            .where((f) => f.path != null)
            .take(remaining)
            .map((f) => XFile(f.path!));
        setState(() => _pickedImages.addAll(newFiles));
      }
    } else {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _pickedImages.addAll(images.take(remaining)));
      }
    }

    // Notify if some images were skipped
    if (_pickedImages.length >= _maxImages && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo limit reached ($_maxImages max)'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a category')));
      return;
    }
    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Uploading images...';
      _uploadProgress = 0.0;
    });

    try {
      // Step 1: Upload images to Cloudinary
      final List<String> imageUrls =
          await CloudinaryService.uploadMultipleImages(
            _pickedImages.map((img) => img.path).toList(),
            onImageUploaded: (index, total, url) {
              if (mounted) {
                setState(() {
                  _uploadProgress = index / total;
                  _uploadStatus = 'Uploaded image $index of $total';
                });
              }
            },
          );

      if (mounted) setState(() => _uploadStatus = 'Saving post...');

      // Step 2: Save post with Cloudinary image URLs to Firebase
      final user = FirebaseAuth.instance.currentUser;
      final DatabaseReference postsRef = FirebaseDatabase.instance.ref('posts');
      final DatabaseReference newPostRef = postsRef.push();
      await newPostRef.set({
        'title': _titleController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'category': _selectedCategory,
        'condition': _conditionController.text.trim(),
        'contactInfo': _contactInfoController.text.trim(),
        'description': _descriptionController.text.trim(),
        'createdAt': ServerValue.timestamp,
        'userId': user?.uid ?? 'anonymous',
        'userName': user?.displayName ?? 'User Name',
        'images': imageUrls,
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedCategory = null;
          _pickedImages.clear();
          _uploadStatus = '';
          _uploadProgress = 0.0;
        });
        _titleController.clear();
        _priceController.clear();
        _conditionController.clear();
        _contactInfoController.clear();
        _descriptionController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post published successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadStatus = '';
          _uploadProgress = 0.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker area
                const Text(
                  "Photos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // --- Empty state: tap to pick ---
                if (_pickedImages.isEmpty)
                  InkWell(
                    onTap: _isLoading ? null : _pickImages,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.blue[600],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Add Photos (up to $_maxImages)",
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // --- Image grid with "add more" tile ---
                if (_pickedImages.isNotEmpty)
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(8),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                              ),
                          // +1 for the "add more" tile (only if under limit)
                          itemCount:
                              _pickedImages.length +
                              (_pickedImages.length < _maxImages ? 1 : 0),
                          itemBuilder: (context, index) {
                            // "Add more" tile
                            if (index == _pickedImages.length) {
                              return InkWell(
                                onTap: _isLoading ? null : _pickImages,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 28,
                                        color: Colors.blue[600],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          color: Colors.blue[600],
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Image tile with remove button
                            return Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(_pickedImages[index].path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: _isLoading
                                        ? null
                                        : () => setState(
                                            () => _pickedImages.removeAt(index),
                                          ),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        // Photo count badge
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_pickedImages.length}/$_maxImages photo(s)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (_pickedImages.isNotEmpty)
                                GestureDetector(
                                  onTap: _isLoading
                                      ? null
                                      : () => setState(
                                          () => _pickedImages.clear(),
                                        ),
                                  child: Text(
                                    'Clear All',
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Form Fields
                const Text(
                  "Product Details",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _titleController,
                  label: "Product Title",
                  hint: "What are you selling?",
                  icon: Icons.title,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _priceController,
                        label: "Price",
                        hint: "0.00",
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Category",
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: Colors.blue.shade600,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        hint: const Text(
                          "Select",
                          style: TextStyle(fontSize: 16),
                        ),
                        isExpanded: true,
                        initialValue: _selectedCategory,
                        items: _categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _conditionController,
                  label: "Condition",
                  hint: "e.g. New, Used - Like New, Used - Good",
                  icon: Icons.star_border,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _contactInfoController,
                  label: "Contact Info",
                  hint: "Phone number or email",
                  icon: Icons.contact_phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildTextField(
                  controller: _descriptionController,
                  label: "Description",
                  hint:
                      "Describe the item you're selling. Add relevant details such as brand, size, specifications etc.",
                  icon: Icons.description_outlined,
                  maxLines: 4,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 24),

                // Upload progress indicator
                if (_isLoading && _uploadStatus.isNotEmpty) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _uploadStatus,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue[600]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPost,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Publishing...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Text(
                            "Publish Post",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        prefixIcon: Padding(
          padding: EdgeInsets.only(
            bottom: maxLines > 1 ? 60.0 : 0,
          ), // Align top if multiline
          child: Icon(icon, color: Colors.grey.shade600),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        alignLabelWithHint: maxLines > 1,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
