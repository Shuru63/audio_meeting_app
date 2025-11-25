import 'package:get/get.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../data/repositories/auth_repository.dart';

class SplashController extends GetxController {
  final LocalStorageService _storageService = Get.find<LocalStorageService>();
  final AuthRepository _authRepository = Get.find<AuthRepository>();

  final RxBool isLoading = true.obs;
  final RxString statusMessage = 'Initializing...'.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Step 1: Check local storage
      statusMessage.value = 'Checking local data...';
      await Future.delayed(const Duration(milliseconds: 500));

      // Step 2: Check authentication
      statusMessage.value = 'Verifying authentication...';
      await Future.delayed(const Duration(milliseconds: 500));

      final user = await _storageService.getUser();

      if (user != null) {
        // User exists in local storage, verify with Firebase
        statusMessage.value = 'Verifying session...';
        await Future.delayed(const Duration(milliseconds: 500));

        final result = await _authRepository.getCurrentUser();

        result.fold(
          (failure) {
            // Session expired or invalid, go to login
            _navigateToLogin();
          },
          (currentUser) {
            // Check if account is still active
            if (currentUser.isActive) {
              _navigateToHome();
            } else {
              // Account deactivated
              _storageService.clearUser();
              _navigateToLogin();
            }
          },
        );
      } else {
        // No user in local storage, go to login
        _navigateToLogin();
      }
    } catch (e) {
      // Error during initialization, go to login
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    statusMessage.value = 'Welcome back!';
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAllNamed(RouteNames.home);
    });
  }

  void _navigateToLogin() {
    statusMessage.value = 'Please login to continue';
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.offAllNamed(RouteNames.login);
    });
  }
}