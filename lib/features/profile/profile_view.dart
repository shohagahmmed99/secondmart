import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:second_mart/features/auth/login_view.dart';
import 'package:second_mart/features/profile/user_details_view.dart';
import 'package:second_mart/features/notification/notification_view.dart';
import 'package:second_mart/features/chat/message_view.dart';
import 'package:second_mart/features/sell/sell_view.dart';
import 'package:second_mart/utils/theme_provider.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final User? _user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_user == null) return;
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .child(_user!.uid)
          .get();
      if (snapshot.exists && mounted) {
        setState(() {
          _userData = Map<String, dynamic>.from(snapshot.value as Map);
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  String get _displayName => _userData?['name'] ?? _user?.displayName ?? 'User';
  String get _email => _userData?['email'] ?? _user?.email ?? '';
  String get _initial =>
      _displayName.isNotEmpty ? _displayName[0].toUpperCase() : '?';

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade400,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Log Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to log out of Second Mart?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, false),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF3A3A3A)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx, true),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0.5,
        title: Text(
          "Menu",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
          ),
        ),
        leading: BackButton(
          color: Theme.of(context).colorScheme.onSurface,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        children: [
          // ── User profile card ─────────────────────────────────────────
          _UserCard(
            displayName: _displayName,
            email: _email,
            initial: _initial,
            profilePic: _userData?['profilePic'],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserDetailsView()),
            ),
          ),

          const SizedBox(height: 20),

          // ── Your Activity ─────────────────────────────────────────────
          _SectionHeader(label: 'Your Activity'),
          _MenuTile(
            icon: Icons.storefront_rounded,
            iconColor: const Color(0xFF3498DB),
            label: 'My Listings',
            subtitle: 'View all your posted items',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserDetailsView()),
            ),
          ),
          _MenuTile(
            icon: Icons.add_box_rounded,
            iconColor: const Color(0xFF27AE60),
            label: 'Sell an Item',
            subtitle: 'Post something for sale',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SellView()),
            ),
          ),
          _MenuTile(
            icon: Icons.chat_bubble_rounded,
            iconColor: const Color(0xFF8E44AD),
            label: 'Messages',
            subtitle: 'View your conversations',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MessageView()),
            ),
          ),
          _MenuTile(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFFE67E22),
            label: 'Notifications',
            subtitle: 'See your latest alerts',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationView()),
            ),
          ),

          const SizedBox(height: 20),

          // ── Account ───────────────────────────────────────────────────
          _SectionHeader(label: 'Account'),
          _MenuTile(
            icon: Icons.person_rounded,
            iconColor: const Color(0xFF3498DB),
            label: 'Edit Profile',
            subtitle: 'Update your name, bio & photo',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UserDetailsView()),
            ),
          ),
          // Dark mode toggle
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeProvider(),
            builder: (context, themeMode, _) {
              final isDark = themeMode == ThemeMode.dark;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8E44AD).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: const Color(0xFF8E44AD),
                      size: 22,
                    ),
                  ),
                  title: const Text(
                    'Dark Mode',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    isDark ? 'Dark theme is on' : 'Light theme is on',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeColor: const Color(0xFF3498DB),
                    onChanged: (_) => ThemeProvider().toggleTheme(),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onTap: () => ThemeProvider().toggleTheme(),
                ),
              );
            },
          ),
          _MenuTile(
            icon: Icons.lock_rounded,
            iconColor: Colors.grey.shade600,
            label: 'Privacy & Security',
            subtitle: 'Manage your account security',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
          ),

          const SizedBox(height: 20),

          // ── Support ───────────────────────────────────────────────────
          _SectionHeader(label: 'Support'),
          _MenuTile(
            icon: Icons.help_rounded,
            iconColor: Colors.teal,
            label: 'Help Center',
            subtitle: 'Get help with Second Mart',
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Coming soon')));
            },
          ),
          _MenuTile(
            icon: Icons.info_rounded,
            iconColor: Colors.blueGrey,
            label: 'About',
            subtitle: 'App version & information',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Second Mart',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(
                  Icons.shopping_cart,
                  color: Color(0xFF3498DB),
                  size: 40,
                ),
                children: [
                  const Text(
                    'Second Mart is a marketplace app to buy and sell second-hand items.',
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),

          // ── Log Out ───────────────────────────────────────────────────
          GestureDetector(
            onTap: _logout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A1C1C)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.shade900
                      : Colors.red.shade100,
                ),
              ),
              child: Center(
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.red.shade300
                          : Colors.red.shade400,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Log Out',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade300
                            : Colors.red.shade400,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User profile card at the top
// ─────────────────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String initial;
  final String? profilePic;
  final VoidCallback onTap;

  const _UserCard({
    required this.displayName,
    required this.email,
    required this.initial,
    required this.profilePic,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF3498DB),
              backgroundImage: profilePic != null
                  ? NetworkImage(profilePic!)
                  : null,
              child: profilePic == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (email.isNotEmpty)
                    Text(
                      email,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'View your profile',
                    style: TextStyle(
                      color: const Color(0xFF3498DB),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header label
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[400],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Menu list tile
// ─────────────────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
