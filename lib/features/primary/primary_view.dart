import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:second_mart/features/chat/message_view.dart' show MessageView;
import 'package:second_mart/features/home/home_view.dart' show HomeView;
import 'package:second_mart/features/notification/notification_view.dart';
import 'package:second_mart/features/profile/profile_view.dart';
import 'package:second_mart/features/sell/sell_view.dart' show SellView;
import 'package:second_mart/features/widgets/search/search.dart';

class PrimaryView extends StatefulWidget {
  const PrimaryView({super.key});

  @override
  State<PrimaryView> createState() => _PrimaryViewState();
}

class _PrimaryViewState extends State<PrimaryView> {
  int selectedIndex = 0;
  int _unreadCount = 0;
  int _unreadMessageCount = 0;
  StreamSubscription<DatabaseEvent>? _notifSubscription;
  StreamSubscription<DatabaseEvent>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _listenToUnreadNotifications();
    _listenToUnreadMessages();
  }

  void _listenToUnreadNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _notifSubscription = FirebaseDatabase.instance
        .ref('notifications/$uid')
        .onValue
        .listen((event) {
          if (!mounted) return;

          // Use a Set to count unique senders
          final Set<String> unreadSenders = {};

          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = Map<dynamic, dynamic>.from(
              event.snapshot.value as Map,
            );
            for (final entry in data.values) {
              if (entry is Map && entry['isRead'] == false) {
                final senderId = entry['senderId']?.toString();
                if (senderId != null) {
                  unreadSenders.add(senderId);
                }
              }
            }
          }
          setState(() => _unreadCount = unreadSenders.length);
        });
  }

  void _listenToUnreadMessages() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _messageSubscription = FirebaseDatabase.instance
        .ref('user_chats/$uid')
        .onValue
        .listen((event) {
          if (!mounted) return;
          int peopleCount = 0;
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = Map<dynamic, dynamic>.from(
              event.snapshot.value as Map,
            );
            for (final entry in data.values) {
              if (entry is Map) {
                // Count this chat if it has at least one unread message
                if ((entry['unreadCount'] as int? ?? 0) > 0) {
                  peopleCount++;
                }
              }
            }
          }
          setState(() => _unreadMessageCount = peopleCount);
        });
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withOpacity(0.5),
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.cardColor,
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
                  // Icon with gradient background
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3498DB).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Exit Second Mart?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Are you sure you want to leave the app?',
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
                      // Stay button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(false),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(14),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Stay',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Exit button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(true),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF3498DB,
                                  ).withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Exit',
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
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: theme.cardColor,
            toolbarHeight: selectedIndex == 0 ? kToolbarHeight : 20,
            title: selectedIndex == 0
                ? const Text(
                    "Second Mart",
                    style: TextStyle(
                      color: Color(0xFF3498DB),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16),
            actions: selectedIndex == 0
                ? [
                    GestureDetector(
                      onTap: () {
                        showSearch(context: context, delegate: Search());
                      },
                      child: Image.asset(
                        "assets/images/searchh.png",
                        width: 24,
                        height: 24,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.menu, color: theme.colorScheme.onSurface),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, a, b) => const ProfileView(),
                            transitionsBuilder: (_, animation, b, child) {
                              return SlideTransition(
                                position:
                                    Tween<Offset>(
                                      begin: const Offset(1.0, 0.0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    ),
                                child: child,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ]
                : null,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: TabBar(
                onTap: (index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                indicatorColor: Colors.transparent,
                labelColor: const Color(0xFF3498DB),
                unselectedLabelColor: Colors.grey,
                padding: const EdgeInsets.all(0),
                tabs: [
                  Tab(
                    icon: (selectedIndex == 0)
                        ? const Image(
                            image: AssetImage("assets/images/home_fill.png"),
                            width: 24,
                            height: 24,
                            color: Color(0xFF3498DB),
                          )
                        : Image(
                            image: const AssetImage("assets/images/home.png"),
                            width: 24,
                            height: 24,
                            color: isDark ? Colors.grey[400] : null,
                          ),
                  ),
                  Tab(
                    icon: (selectedIndex == 1)
                        ? const Image(
                            image: AssetImage("assets/images/sell_fill.png"),
                            width: 28,
                            height: 28,
                            color: Color(0xFF3498DB),
                          )
                        : Image(
                            image: const AssetImage("assets/images/sell.png"),
                            width: 24,
                            height: 24,
                            color: isDark ? Colors.grey[400] : null,
                          ),
                  ),
                  Tab(
                    icon: Badge(
                      isLabelVisible: _unreadMessageCount > 0,
                      label: Text(
                        _unreadMessageCount > 99
                            ? '99+'
                            : '$_unreadMessageCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFFFF4B6E),
                      child: (selectedIndex == 2)
                          ? const Image(
                              image: AssetImage(
                                "assets/images/messenger_fill.png",
                              ),
                              width: 24,
                              height: 24,
                              color: Color(0xFF3498DB),
                            )
                          : Image(
                              image: const AssetImage("assets/images/messenger.png"),
                              width: 24,
                              height: 24,
                              color: isDark ? Colors.grey[400] : null,
                            ),
                    ),
                  ),
                  // Notification tab with unread badge
                  Tab(
                    icon: Badge(
                      isLabelVisible: _unreadCount > 0,
                      label: Text(
                        _unreadCount > 99 ? '99+' : '$_unreadCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFFFF4B6E),
                      child: (selectedIndex == 3)
                          ? const Image(
                              image: AssetImage(
                                "assets/images/notification_fill.png",
                              ),
                              width: 24,
                              height: 24,
                              color: Color(0xFF3498DB),
                            )
                          : Image(
                              image: const AssetImage(
                                "assets/images/notification.png",
                              ),
                              width: 24,
                              height: 24,
                              color: isDark ? Colors.grey[400] : null,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: IndexedStack(
            index: selectedIndex,
            children: const [
              HomeView(),
              SellView(),
              MessageView(),
              NotificationView(),
            ],
          ),
        ),
      ),
    );
  }
}
