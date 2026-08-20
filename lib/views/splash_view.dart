import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_inventory_provider.dart';
import '../providers/app_settings_provider.dart';
import '../services/localization_service.dart';
import '../main.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  bool _minTimeElapsed = false;
  bool _navigationTriggered = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // 1200ms entrance timeline for logo scale and fade
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Set a minimum timer of 2000 milliseconds before transitioning out
    _timer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkNavigation();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _checkNavigation() {
    if (!mounted || _navigationTriggered) return;

    final inventory = context.read<AppInventoryProvider>();
    if (_minTimeElapsed && !inventory.isInitialLoading && inventory.activeList != null) {
      _navigationTriggered = true;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const MainHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Elegant combined fade and subtle zoom-out transition
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 1.03, end: 1.0).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInOutCubic,
                  ),
                ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 700),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsProvider>();
    context.watch<AppInventoryProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger navigation check whenever provider properties update in case loading completes after the minimum timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNavigation();
    });

    final isHindi = settings.language == AppLanguage.hindi;

    // Premium Slate theme-compatible background colors
    final bgGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
          );

    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: bgGradient,
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Icon
                  Image.asset(
                    'assets/icon/logo.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  // Name (Bilingual supported)
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: isHindi ? 'घरकी' : 'gharki',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: titleColor,
                            letterSpacing: isHindi ? 0 : -0.5,
                          ),
                        ),
                        TextSpan(
                          text: isHindi ? 'लिस्ट' : 'list',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF00C853),
                            letterSpacing: isHindi ? 0 : -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
