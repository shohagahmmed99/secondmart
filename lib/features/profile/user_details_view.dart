import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:second_mart/utils/cloudinary_service.dart';
import 'package:second_mart/features/profile/edit_profile_view.dart';
import 'package:second_mart/features/chat/chat_detail_view.dart';

class UserDetailsView extends StatefulWidget {
  final String? uid;
  const UserDetailsView({super.key, this.uid});

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String get _targetUid => widget.uid ?? _currentUser?.uid ?? '';
  bool get _isMe => _targetUid == _currentUser?.uid;

  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_targetUid.isEmpty) return;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .child(_targetUid)
          .get();
      if (snapshot.exists) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      setState(() => _isLoading = false);
    }
  }

  void _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileView(initialData: _userData),
      ),
    );

    if (result == true) {
      _fetchUserData(); // Refresh if data changed
    }
  }

  Future<void> _updateProfilePic() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isLoading = true);
    debugPrint("--- Starting profile pic update for ${image.path}");

    try {
      // 1. Upload to Cloudinary (same service as used for products)
      final String? imageUrl = await CloudinaryService.uploadImage(image.path);
      debugPrint("--- Uploaded to Cloudinary: $imageUrl");

      if (imageUrl != null) {
        // 2. Update Firebase Realtime Database
        await FirebaseDatabase.instance.ref('users').child(_targetUid).update({
          'profilePic': imageUrl,
        });
        debugPrint("--- Updated Realtime Database");

        // 3. Update Firebase Auth profile
        if (_isMe && _currentUser != null) {
          await _currentUser!.updatePhotoURL(imageUrl);
          await _currentUser!.reload();
          debugPrint("--- Updated Firebase Auth profile");
        }

        // 4. Refresh local state
        await _fetchUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      } else {
        throw Exception("Failed to get image URL from Cloudinary");
      }
    } catch (e) {
      debugPrint("Error updating profile pic: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isCoverLoading = false;

  Future<void> _updateCoverPic() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    setState(() => _isCoverLoading = true);

    try {
      final String? imageUrl = await CloudinaryService.uploadImage(image.path);

      if (imageUrl != null) {
        await FirebaseDatabase.instance.ref('users').child(_targetUid).update({
          'coverPic': imageUrl,
        });

        await _fetchUserData();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cover photo updated!')));
        }
      }
    } catch (e) {
      debugPrint("Error updating cover pic: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating cover: $e')));
      }
    } finally {
      if (mounted) setState(() => _isCoverLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName =
        _userData?['name'] ??
        (_isMe ? _currentUser?.displayName : null) ??
        'User';
    final email =
        _userData?['email'] ?? (_isMe ? _currentUser?.email : null) ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFC9CCD1), // FB Lite gray background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: Colors.black,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          displayName,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section (Cover + Profile Photo)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    clipBehavior: Clip.none,
                    children: [
                      // Cover Photo
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: _userData?['coverPic'] != null
                            ? Image.network(
                                _userData!['coverPic'],
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                      ),
                      if (_isCoverLoading)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // Add Cover Button
                      if (_isMe)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: _isCoverLoading ? null : _updateCoverPic,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    "Add Cover Photo",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      // Profile Photo
                      Positioned(
                        bottom: -50,
                        left: 16,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final pic = _userData?['profilePic'];
                                if (pic != null && pic.toString().isNotEmpty) {
                                  _openFullScreenImage([pic.toString()], 0);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  key: ValueKey(
                                    _userData?['profilePic'] ?? 'default',
                                  ),
                                  radius: 60,
                                  backgroundColor: Colors.blue[600],
                                  backgroundImage:
                                      (_userData?['profilePic'] != null &&
                                          _userData!['profilePic']
                                              .toString()
                                              .isNotEmpty)
                                      ? NetworkImage(_userData!['profilePic'])
                                      : null,
                                  child:
                                      (_userData?['profilePic'] == null ||
                                              _userData!['profilePic']
                                                  .toString()
                                                  .isEmpty) &&
                                          !_isLoading
                                      ? Text(
                                          initial,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 48,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                            if (_isLoading)
                              Container(
                                width: 128,
                                height: 128,
                                decoration: const BoxDecoration(
                                  color: Colors.black26,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (!_isLoading && _isMe)
                              Positioned(
                                bottom: 5,
                                right: 5,
                                child: GestureDetector(
                                  onTap: _updateProfilePic,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 55),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _userData?['bio'] ?? "Add Bio",
                          style: TextStyle(
                            color: _userData?['bio'] != null
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Action Buttons
                  if (_isMe)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _navigateToEditProfile,
                              icon: const Icon(Icons.edit, color: Colors.black),
                              label: const Text("Edit Profile"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.more_horiz,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailView(
                                      otherUserId: _targetUid,
                                      otherUserName: displayName,
                                      otherUserProfilePic:
                                          _userData?['profilePic'],
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.message,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Message",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0084FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Details Section
            InkWell(
              onTap: _isMe ? _navigateToEditProfile : null,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailItem(
                      Icons.work,
                      _userData?['work'] ??
                          (_isMe ? "Add workplace" : "No workplace info"),
                      isPlaceholder: _userData?['work'] == null && _isMe,
                    ),
                    _buildDetailItem(
                      Icons.school,
                      _userData?['education'] ??
                          (_isMe ? "Add education" : "No education info"),
                      isPlaceholder: _userData?['education'] == null && _isMe,
                    ),
                    _buildDetailItem(
                      Icons.home,
                      _userData?['currentCity'] != null
                          ? "Lives in ${_userData!['currentCity']}"
                          : (_isMe ? "Add current city" : "No city info"),
                      isPlaceholder: _userData?['currentCity'] == null && _isMe,
                    ),
                    _buildDetailItem(
                      Icons.location_on,
                      _userData?['hometown'] != null
                          ? "From ${_userData!['hometown']}"
                          : (_isMe ? "Add hometown" : "No hometown info"),
                      isPlaceholder: _userData?['hometown'] == null && _isMe,
                    ),
                    _buildDetailItem(
                      Icons.access_time,
                      "Joined ${_formatJoinedDate(_userData?['createdAt'])}",
                    ),
                    if (_isMe) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _navigateToEditProfile,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("See your About info"),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatJoinedDate(dynamic date) {
    if (date == null) return "Unknown date";
    try {
      final dateTime = DateTime.parse(date.toString());
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return "${months[dateTime.month - 1]} ${dateTime.year}";
    } catch (e) {
      return "recently";
    }
  }

  Widget _buildDetailItem(
    IconData icon,
    String text, {
    bool isPlaceholder = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isPlaceholder ? Colors.blue[600] : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage(List<String> list, int i) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImageViewer(imageUrls: list, currentIndex: i),
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int currentIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.currentIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                child: Center(
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                  ),
                ),
              );
            },
          ),

          // Indicator (like 1/5)
          Positioned(
            bottom: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${widget.imageUrls.length}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
