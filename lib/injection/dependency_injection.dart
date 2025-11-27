import 'package:get/get.dart';

import '../core/services/firebase_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/webrtc_service.dart';
import '../core/services/recording_service.dart';
import '../core/services/navigation_service.dart';   // <-- ADD THIS IMPORT

import '../data/repositories/auth_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/user_repository.dart';

// Controllers
import '../presentation/screens/splash/splash_controller.dart';

class DependencyInjection {
  static Future<void> init() async {
    try {
      print('🔄 Starting Dependency Injection...');

      // LocalStorageService
      await Get.putAsync<LocalStorageService>(
        () async {
          final instance = await LocalStorageService.getInstance();
          print('✅ LocalStorageService initialized');
          return instance;
        },
        permanent: true,
      );

      // Core Services
      Get.put<FirebaseService>(FirebaseService(), permanent: true);
      Get.put<NotificationService>(NotificationService(), permanent: true);
      Get.put<WebRTCService>(WebRTCService(), permanent: true);
      Get.put<RecordingService>(RecordingService(), permanent: true);

      // ⭐ REGISTER NAVIGATION SERVICE
      Get.lazyPut<NavigationService>(
        () => NavigationService(),
        fenix: true,
      );

      // Repositories
      Get.lazyPut<AuthRepository>(
        () => AuthRepository(Get.find<FirebaseService>()),
        fenix: true,
      );

      Get.lazyPut<MeetingRepository>(
        () => MeetingRepository(Get.find<FirebaseService>()),
        fenix: true,
      );

      Get.lazyPut<UserRepository>(
        () => UserRepository(Get.find<FirebaseService>()),
        fenix: true,
      );

      // Controllers
      Get.put<SplashController>(SplashController(), permanent: false);

      print('✅ All dependencies injected successfully');
    } catch (e, stack) {
      print('❌ Dependency Injection failed: $e');
      print('Stack trace: $stack');
      rethrow;
    }
  }
}
