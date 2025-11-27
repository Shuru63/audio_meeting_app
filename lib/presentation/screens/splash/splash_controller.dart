import 'package:get/get.dart';
import '../../../core/router/route_names.dart';
import '../../../core/services/local_storage_service.dart';
import '../../../core/services/navigation_service.dart'; // Add this
import '../../../data/repositories/auth_repository.dart';
import '../../../data/models/user_model.dart';

class SplashController extends GetxController {
  final RxString statusMessage = 'Initializing...'.obs;
  final RxDouble progressValue = 0.0.obs;
  final RxBool initializationComplete = false.obs;

  final NavigationService _navigationService = Get.find<NavigationService>();

  @override
  void onInit() {
    super.onInit();
    print('🔄 SplashController initialized');
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      print('🚀 Starting app initialization...');
      
      // Add a small delay to ensure dependencies are fully loaded
      await Future.delayed(const Duration(milliseconds: 500));

      await _performInitializationSteps();
      
      // Check dependencies are available
      if (!Get.isRegistered<LocalStorageService>() || 
          !Get.isRegistered<AuthRepository>()) {
        throw Exception('Dependencies not initialized');
      }

      final LocalStorageService storageService = Get.find<LocalStorageService>();
      final AuthRepository authRepository = Get.find<AuthRepository>();

      // Check if user exists in local storage
      final UserModel? user = await storageService.getUser();
      final String? token = storageService.getToken();

      print('👤 User check - User: ${user?.email}, Token: ${token != null && token.isNotEmpty}');

      if (_isUserValid(user, token)) {
        await _verifyUserSession(user!, authRepository);
      } else {
        _navigateToLogin();
      }
    } catch (e, stack) {
      print('❌ Initialization error: $e');
      print('Stack trace: $stack');
      _handleInitializationError(e);
    }
  }

  bool _isUserValid(UserModel? user, String? token) {
    return user != null && 
           user.id.isNotEmpty && 
           user.email.isNotEmpty &&
           token != null && 
           token.isNotEmpty;
  }

  Future<void> _performInitializationSteps() async {
    const initializationSteps = [
      {'message': 'Loading app resources...', 'progress': 0.2},
      {'message': 'Setting up services...', 'progress': 0.4},
      {'message': 'Checking authentication...', 'progress': 0.7},
      {'message': 'Finalizing setup...', 'progress': 0.9},
    ];

    for (final step in initializationSteps) {
      statusMessage.value = step['message'] as String;
      progressValue.value = step['progress'] as double;
      await Future.delayed(const Duration(milliseconds: 600));
    }
  }

  Future<void> _verifyUserSession(UserModel user, AuthRepository authRepository) async {
    try {
      statusMessage.value = 'Verifying session...';
      progressValue.value = 0.95;

      // Verify with Firebase/auth repository
      final result = await authRepository.getCurrentUser();

      result.fold(
        (failure) {
          print('❌ Session verification failed: $failure');
          _clearUserData();
          _navigateToLoginWithMessage('Session expired. Please login again.');
        },
        (currentUser) {
          if (currentUser.isActive) {
            print('✅ Session valid, navigating to home');
            _navigateToHome();
          } else {
            print('❌ Account deactivated');
            _clearUserData();
            _navigateToLoginWithMessage('Account deactivated. Please contact support.');
          }
        },
      );
    } catch (e, stack) {
      print('❌ Session verification error: $e');
      print('Stack trace: $stack');
      await _clearUserData();
      _navigateToLoginWithMessage('Session verification failed');
    }
  }

  Future<void> _clearUserData() async {
    try {
      final storageService = Get.find<LocalStorageService>();
      await storageService.clearUser();
      await storageService.clearToken();
      print('✅ User data cleared');
    } catch (e) {
      print('❌ Error clearing user data: $e');
    }
  }

  void _navigateToHome() {
    statusMessage.value = 'Welcome back!';
    progressValue.value = 1.0;
    initializationComplete.value = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      print('🏠 Navigating to Home');
      _navigationService.go(RouteNames.home);
    });
  }

  void _navigateToLogin() {
    statusMessage.value = 'Redirecting to login...';
    progressValue.value = 1.0;
    initializationComplete.value = true;
    
    Future.delayed(const Duration(milliseconds: 800), () {
      print('🔐 Navigating to Login');
      _navigationService.go(RouteNames.login);
    });
  }

  void _navigateToLoginWithMessage(String message) {
    statusMessage.value = message;
    progressValue.value = 1.0;
    initializationComplete.value = true;
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      print('🔐 Navigating to Login with message: $message');
      _navigationService.go(RouteNames.login);
    });
  }

  void _handleInitializationError(dynamic error) {
    statusMessage.value = 'Initialization failed. Redirecting...';
    progressValue.value = 1.0;
    initializationComplete.value = true;
    
    Future.delayed(const Duration(milliseconds: 1500), () {
      print('❌ Initialization failed, navigating to login');
      _navigationService.go(RouteNames.login);
    });
  }
}