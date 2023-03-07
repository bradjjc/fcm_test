import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMHelper {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<String?> getToken() async {
    String? token = await _firebaseMessaging.getToken();
    return token;
  }

  Future<void> initialize() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    //포그라운드 수신을 위한 채널 개설
    const AndroidNotificationChannel androidNotificationChannel =
        AndroidNotificationChannel(
      'high_importance_channel', // 임의의 id
      'High Importance Notifications', // 설정에 보일 채널명
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max, // 포그라운드 받을려면 중요도를 MAX해놓아야함
    );

    // Notification Channel을 디바이스에 생성
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidNotificationChannel);

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings()),
      //클릭 메세지 액션
      // onDidReceiveNotificationResponse: onSelectNotification,
      // onDidReceiveBackgroundNotificationResponse:  onSelectNotification,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        print('??? ${notificationResponse.payload}');

        var entries = notificationResponse.payload!
            .substring(1, notificationResponse.payload!.length - 1)
            .split(RegExp(r',\s?'))
            .map((e) => e.split(RegExp(r':\s?')))
            .map((e) => MapEntry(e.first, e.last));
        var result = Map.fromEntries(entries);

        print('action ${result['action']}');
      },
      // onDidReceiveBackgroundNotificationResponse:  onSelectNotification,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Custom handling of message
      // For example, display a local notification using flutter_local_notifications package
      print('Received a message from FCM: ${message.notification!.title}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      var androidNotiDetails = const AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
      );
      var iOSNotiDetails = const DarwinNotificationDetails();
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: androidNotiDetails,
            iOS: iOSNotiDetails,
          ),
          payload: message.data.toString(),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Custom handling of notification tap when the app is in the foreground
    });

    FirebaseMessaging.onBackgroundMessage((message) async {
      // Custom handling of notification tap when the app is in the background or closed
      // For example, navigate to a specific screen in the app
    });
  }
}
