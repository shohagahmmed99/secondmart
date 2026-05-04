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
      int count = 0;
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map,
        );
        for (final entry in data.values) {
          if (entry is Map && entry['isRead'] == false) {
            count++;
          }
        }
      }
      setState(() => _unreadCount = count);
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
      int count = 0;
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = Map<dynamic, dynamic>.from(
          event.snapshot.value as Map,
        );
        for (final entry in data.values) {
          if (entry is Map) {
            count += (entry['unreadCount'] as int? ?? 0);
          }
        }
      }
      setState(() => _unreadMessageCount = count);
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final bool? shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes', style: TextStyle(color: Color(0xFF3498DB), fontWeight: FontWeight.bold)),
              ),
            ],
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
            backgroundColor: Colors.white,
            toolbarHeight: selectedIndex == 0 ? kToolbarHeight : 20,
            title: selectedIndex == 0
                ? const Text(
                    "Second Mart",
                    style: TextStyle(color: Color(0xFF3498DB), fontSize: 22, fontWeight: FontWeight.bold),
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
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.black),
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (_, a, b) => const ProfileView(),
                            transitionsBuilder: (_, animation, b, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                )),
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
                        : const Image(
                            image: AssetImage("assets/images/home.png"),
                            width: 24,
                            height: 24,
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
                        : const Image(
                            image: AssetImage("assets/images/sell.png"),
                            width: 24,
                            height: 24,
                          ),
                  ),
                  Tab(
                    icon: Badge(
                      isLabelVisible: _unreadMessageCount > 0,
                      label: Text(
                        _unreadMessageCount > 99 ? '99+' : '$_unreadMessageCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFFFF4B6E),
                      child: (selectedIndex == 2)
                          ? const Image(
                              image: AssetImage("assets/images/messenger_fill.png"),
                              width: 24,
                              height: 24,
                              color: Color(0xFF3498DB),
                            )
                          : const Image(
                              image: AssetImage("assets/images/messenger.png"),
                              width: 24,
                              height: 24,
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
                          : const Image(
                              image: AssetImage(
                                  "assets/images/notification.png"),
                              width: 24,
                              height: 24,
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
