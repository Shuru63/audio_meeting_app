import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final Logger _logger = Logger();

  // Callback for notification tap
  static Function(Map<String, String?> payload)? onNotificationTap;

  static Future<void> init({Function(Map<String, String?>)? onNotificationTapped}) async {
    final instance = NotificationService();
    onNotificationTap = onNotificationTapped;
    await instance._initializeFirebaseMessaging();
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _logger.i('User granted permission: ${settings.authorizationStatus}');

      // Get FCM token
      String? token = await _firebaseMessaging.getToken();
      _logger.i('FCM Token: $token');

      // Configure foreground notification presentation
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Get initial message if app was opened from terminated state
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      // Handle token refresh
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _logger.i('FCM Token refreshed: $token');
      });

    } catch (e) {
      _logger.e('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Foreground message received: ${message.messageId}');
    
    try {
      // In foreground, Firebase automatically shows notifications
      // We can handle additional logic here if needed
      if (message.notification != null) {
        _logger.i('Notification received - Title: ${message.notification!.title}, Body: ${message.notification!.body}');
        
        // You can show a custom dialog or update UI here
        // For example, show a snackbar or update badge count
        _showInAppNotification(message);
      }
      
      // Handle data messages
      if (message.data.isNotEmpty) {
        _logger.i('Data payload: ${message.data}');
        // Process data message and update UI accordingly
      }
    } catch (e) {
      _logger.e('Error handling foreground message: $e');
    }
  }

  void _showInAppNotification(RemoteMessage message) {
    // Show custom in-app notification (like a snackbar or banner)
    // This is optional - Firebase already shows system notifications
    if (Get.isSnackbarOpen) {
      Get.back(); // Close existing snackbar
    }
    
    Get.snackbar(
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
      onTap: (_) {
        _handleNotificationTap(_convertMapToStringMap(message.data));
      },
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.i('Message opened app: ${message.messageId}');
    _handleNotificationTap(_convertMapToStringMap(message.data));
  }

  // Helper method to convert Map<String, dynamic> to Map<String, String?>
  Map<String, String?> _convertMapToStringMap(Map<String, dynamic> originalMap) {
    final Map<String, String?> convertedMap = {};
    originalMap.forEach((key, value) {
      convertedMap[key] = value?.toString();
    });
    return convertedMap;
  }

  void _handleNotificationTap(Map<String, String?> payload) {
    _logger.i('Notification tapped with payload: $payload');
    
    // Handle navigation based on payload
    if (payload.containsKey('meetingId') || payload.containsKey('meeting_code')) {
      final meetingId = payload['meetingId'] ?? payload['meeting_code'];
      if (meetingId != null) {
        // Navigate to meeting screen using GetX
        _logger.i('Should navigate to meeting: $meetingId');
        
        // Call the callback if provided
        onNotificationTap?.call(payload);
        
        // Example navigation (adjust based on your routing)
        // Get.toNamed('/meeting', arguments: {'meetingId': meetingId});
      }
    }
  }

  // Method to send custom notifications (for local testing or specific use cases)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    Map<String, String?>? payload,
  }) async {
    try {
      // Since we're not using AwesomeNotifications, we'll use Get.snackbar for in-app notifications
      // For system notifications, you'd need to use Firebase Cloud Messaging from your server
      Get.snackbar(
        title,
        body,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(10),
        borderRadius: 8,
        onTap: (_) {
          if (payload != null) {
            _handleNotificationTap(payload);
          }
        },
      );
      _logger.i('Local notification shown: $title');
    } catch (e) {
      _logger.e('Error showing local notification: $e');
    }
  }

  Future<void> showMeetingInviteNotification({
    required String meetingCode,
    required String hostName,
  }) async {
    // This would typically be sent from your server via FCM
    // For local testing, use the local notification method
    await showLocalNotification(
      title: 'Meeting Invitation',
      body: '$hostName invited you to join meeting: $meetingCode',
      payload: {
        'type': 'meeting_invite',
        'meeting_code': meetingCode,
        'host_name': hostName,
      },
    );
  }

  Future<void> showMeetingStartedNotification({
    required String meetingId,
    required String meetingTitle,
  }) async {
    await showLocalNotification(
      title: 'Meeting Started',
      body: meetingTitle,
      payload: {
        'type': 'meeting_started',
        'meeting_id': meetingId,
        'meeting_title': meetingTitle,
      },
    );
  }

  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    _logger.i('Subscribed to topic: $topic');
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    _logger.i('Unsubscribed from topic: $topic');
  }

  // Method to handle notification permissions
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  // Method to check if notifications are enabled
  Future<bool> isNotificationsEnabled() async {
    final settings = await getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Method to request permission if not granted
  Future<void> requestNotificationPermission() async {
    final settings = await getNotificationSettings();
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await _initializeFirebaseMessaging();
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase in background
  await Firebase.initializeApp();
  
  final Logger logger = Logger();
  logger.i('Background message received: ${message.messageId}');
  
  // Firebase automatically handles background notifications
  // You can add additional background processing here if needed
  
  // For data-only messages, you might want to schedule a local notification
  // but since we're not using AwesomeNotifications, Firebase will handle display
  
  logger.i('Background message data: ${message.data}');
  logger.i('Background notification: ${message.notification}');
}