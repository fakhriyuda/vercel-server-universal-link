// lib/services/push_messaging.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

// ===== Required: top-level background handler =====
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Make sure Firebase is initialized in the background isolate.
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Already initialized or not needed on some platforms.
  }
  // TODO: log/route silently if you need
  debugPrint('[BG] messageId=${message.messageId} data=${message.data}');
}

class PushMessaging {
  PushMessaging._();
  static final PushMessaging I = PushMessaging._();

  final _messaging = FirebaseMessaging.instance;
  final _fln = FlutterLocalNotificationsPlugin();

  // Android notification channel for foreground messages
  static const AndroidNotificationChannel _defaultChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance',
    description: 'Used for important notifications.',
    importance: Importance.high,
    playSound: true,
  );

  Future<void> init({
    required Future<void> Function(RemoteMessage)? onTap,
  }) async {
    // 1) Set the global background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2) Initialize local notifications (for foreground display)
    await _initLocalNotifications(onTap: onTap);

    // 3) Ask permissions (iOS always; Android 13+ via permission_handler)
    await _requestPermissions();

    // 4) iOS: set foreground presentation (banner/sound when app is open)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5) Token logging (and refresh listener)
    final fcmToken = await _messaging.getToken();
    debugPrint('🔔 FCM token: $fcmToken');
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('🔄 FCM token refreshed: $token');
    });

    // iOS APNs token (useful for debugging)
    if (Platform.isIOS) {
      final apns = await _messaging.getAPNSToken();
      debugPrint('🍎 APNs token: $apns'); // may be null until APNs registered
    }

    // 6) Foreground messages → show a local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final n = message.notification;
      final android = n?.android;
      // If the message contains a notification, show it
      if (n != null) {
        await _showLocalNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: n.title ?? '',
          body: n.body ?? '',
          payload: _payloadFromMessage(message),
          androidSmallIcon: android?.smallIcon, // optional if you have custom
        );
      }
      // Handle data-only as needed
      // debugPrint('[FG] data: ${message.data}');
    });

    // 7) App opened from background by tapping a notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (onTap != null) await onTap(message);
    });

    // 8) App launched from terminated state by a notification
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null && onTap != null) {
      await onTap(initial);
    }
  }

  String _payloadFromMessage(RemoteMessage m) {
    // Encode what you need to route (JSON stringify if you like)
    // Here we just fold data map into a querystring-like string.
    return m.data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  Future<void> _initLocalNotifications({
    required Future<void> Function(RemoteMessage)? onTap,
  }) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) async {
        // When user taps a foreground-generated local notification
        final payload = resp.payload ?? '';
        // If you encoded message data -> decode here to RemoteMessage if needed
        // For most apps: route using your own navigation with payload
        debugPrint('🔔 Local notif tap payload: $payload');
      },
    );

    // Create Android channel
    final android = _fln.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(_defaultChannel);
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? androidSmallIcon,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _defaultChannel.id,
        _defaultChannel.name,
        channelDescription: _defaultChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: androidSmallIcon, // keep null to use default app icon
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _fln.show(id, title, body, details, payload: payload);
  }

  Future<void> _requestPermissions() async {
    // iOS (and macOS)
    final settings = await _messaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );
    debugPrint('📛 iOS notif permission: ${settings.authorizationStatus}');

    // Android 13+ needs runtime permission too
    if (Platform.isAndroid) {
      // Use permission_handler for a simple prompt
      // (Alternatively, flutter_local_notifications has requestPermissions on Android)
      try {
        // ignore: deprecated_member_use
        final status = await Permission.notification.request();
        debugPrint('🤖 Android notif permission: $status');
      } catch (_) {
        // If you don't add permission_handler, you can skip this — user will
        // be auto-prompted when you first post a notification on some OEMs,
        // but explicit request is recommended.
      }
    }
  }

  // Convenience helpers
  Future<void> subscribe(String topic) => _messaging.subscribeToTopic(topic);
  Future<void> unsubscribe(String topic) => _messaging.unsubscribeFromTopic(topic);
}
