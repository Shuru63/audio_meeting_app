import 'package:get/get.dart';

import '../core/services/firebase_service.dart';
import '../core/services/local_storage_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/webrtc_service.dart';
import '../core/services/recording_service.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/meeting_repository.dart';
import '../data/repositories/user_repository.dart';

class DependencyInjection {
  static Future<void> init() async {
    // Core Services
    Get.lazyPut<FirebaseService>(() => FirebaseService(), fenix: true);

    /// FIXED: async singleton → must use putAsync()
    await Get.putAsync<LocalStorageService>(
      () => LocalStorageService.getInstance(),
      permanent: true,
    );

    Get.lazyPut<NotificationService>(() => NotificationService(), fenix: true);
    Get.lazyPut<WebRTCService>(() => WebRTCService(), fenix: true);
    Get.lazyPut<RecordingService>(() => RecordingService(), fenix: true);

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
  }
}
