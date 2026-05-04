import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class EditProfileView extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const EditProfileView({super.key, this.initialData});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _workController;
  late TextEditingController _eduController;
  late TextEditingController _cityController;
  late TextEditingController _hometownController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _bioController = TextEditingController(text: data['bio'] ?? '');
    _workController = TextEditingController(text: data['work'] ?? '');
    _eduController = TextEditingController(text: data['education'] ?? '');
    _cityController = TextEditingController(text: data['currentCity'] ?? '');
    _hometownController = TextEditingController(text: data['hometown'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _workController.dispose();
    _eduController.dispose();
    _cityController.dispose();
    _hometownController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final updates = {
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'work': _workController.text.trim(),
        'education': _eduController.text.trim(),
        'currentCity': _cityController.text.trim(),
        'hometown': _hometownController.text.trim(),
      };

      await FirebaseDatabase.instance
          .ref('users')
          .child(user.uid)
          .update(updates);

      // Update Auth display name if changed
      if (_nameController.text.trim() != user.displayName) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate data changed
      }
    } catch (e) {
      debugPrint("Error saving profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: BackButton(color: Colors.black, onPressed: () => Navigator.pop(context)),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Public Details"),
              _buildTextField("Name", _nameController, Icons.person),
              _buildTextField("Bio", _bioController, Icons.info_outline, maxLines: 2),
              const SizedBox(height: 24),
              _buildSectionTitle("Work & Education"),
              _buildTextField("Work", _workController, Icons.work),
              _buildTextField("Education", _eduController, Icons.school),
              const SizedBox(height: 24),
              _buildSectionTitle("Location"),
              _buildTextField("Current City", _cityController, Icons.home),
              _buildTextField("Hometown", _hometownController, Icons.location_on),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
