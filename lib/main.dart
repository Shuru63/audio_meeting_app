import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/navigation_service.dart';
import 'injection/dependency_injection.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting application...');

  try {
    // Initialize Firebase
    print('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized');

    // Initialize Hive
    print('📦 Initializing Hive...');
    await Hive.initFlutter();
    print('✅ Hive initialized');

    // Initialize SharedPreferences Storage (LocalStorageService)
    print('💾 Initializing Local Storage...');
    await LocalStorageService.init();
    print('✅ Local Storage initialized');

    // Initialize Notifications
    print('🔔 Initializing Notifications...');
    await NotificationService.init(
      onNotificationTapped: (payload) {
        // Handle notification tap here
        print('Notification tapped with payload: $payload');
        // Example: Navigate to specific screen based on payload
        if (payload['type'] == 'meeting_invite') {
          final meetingCode = payload['meeting_code'];
          if (meetingCode != null) {
            // Get.toNamed('/meeting', arguments: {'meetingCode': meetingCode});
          }
        }
      },
    );
    print('✅ Notifications initialized');

    // DI Setup (after Firebase & LocalStorage initialized)
    print('🔄 Starting Dependency Injection...');
    await DependencyInjection.init();
    print('✅ Dependency Injection completed');

    // Initialize Navigation Service
    print('🧭 Initializing Navigation Service...');
    final navigationService = NavigationService();
    Get.put<NavigationService>(navigationService, permanent: true);
    print('✅ Navigation Service initialized');

    // Lock App Orientation
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // System UI Settings
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    print('✅ All initializations completed successfully');
    runApp(const MyApp());
  } catch (e, stack) {
    print('❌ Application initialization failed: $e');
    print('Stack trace: $stack');
    
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'App Initialization Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Exit App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) {
        // Initialize NavigationService with router
        final navigationService = Get.find<NavigationService>();
        navigationService.initialize(AppRouter.router);

        return GetMaterialApp.router(
          title: 'Audio Meeting App',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerDelegate: AppRouter.router.routerDelegate,
          routeInformationParser: AppRouter.router.routeInformationParser,
          routeInformationProvider: AppRouter.router.routeInformationProvider,
          defaultTransition: Transition.cupertino,
          transitionDuration: const Duration(milliseconds: 300),
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                // Hide keyboard when tapping outside
                FocusScopeNode currentFocus = FocusScope.of(context);
                if (!currentFocus.hasPrimaryFocus && 
                    currentFocus.focusedChild != null) {
                  currentFocus.focusedChild?.unfocus();
                }
              },
              child: child,
            );
          },
        );
      },
    );
  }
}