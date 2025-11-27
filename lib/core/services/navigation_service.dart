import 'package:flutter/material.dart';   // <-- ADD THIS
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  GoRouter? _router;

  void initialize(GoRouter router) {
    _router = router;
  }

  void go(String location) {
    if (_router != null) {
      _router!.go(location);
    } else {
      print('❌ Router not initialized. Cannot navigate to: $location');
      _fallbackNavigation(location);
    }
  }

  void push(String location) {
    if (_router != null) {
      _router!.push(location);
    } else {
      print('❌ Router not initialized. Cannot push to: $location');
      _fallbackNavigation(location);
    }
  }

  void _fallbackNavigation(String location) {
    final context = Get.context;
    if (context != null && context.mounted) {
      context.go(location);
    } else {
      print('❌ Context is null or not mounted. Deferring navigation to: $location');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final newContext = Get.context;
        if (newContext != null && newContext.mounted) {
          newContext.go(location);
        } else {
          print('❌ Still no context available for navigation');
        }
      });
    }
  }

  bool get isInitialized => _router != null;
}
