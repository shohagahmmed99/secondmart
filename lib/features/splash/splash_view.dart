import 'package:flutter/material.dart';
import 'package:second_mart/features/primary/primary_view.dart';
import 'package:firebase_core/firebase_core.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    try {
      // Initialize Firebase while the splash animation is playing
      await Future.wait([
        Future.delayed(const Duration(seconds: 3)),
        Firebase.initializeApp(),
      ]);
    } catch (e) {
      // Handle initialization error if needed
      debugPrint('Firebase initialization error: $e');
    }

    if (!mounted) return;

    // Navigate to AuthWrapper so it can handle auth state
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const PrimaryView()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_cart, size: 100, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                'Second Mart',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
