import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/firebase_options.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();

  print("Handling a background message: ${message.messageId}");
}

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationsBloc() : super(const NotificationsState()) {
    on<NotificationStatusChanged>(_notificationStatusChanged);
    _initialStatusCheck();
    _onForegroundMessage();
  }

  static Future<void> initializeFCM() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  void _notificationStatusChanged(
      NotificationStatusChanged event, Emitter<NotificationsState> emit) {
    emit(state.copyWith(status: event.status));
  }

  void _initialStatusCheck() async {
    final setting = await messaging.getNotificationSettings();
    add(NotificationStatusChanged(setting.authorizationStatus));
  }

  void _getFCMToken() async {
    final setting = await messaging.getNotificationSettings();
    if (setting.authorizationStatus != AuthorizationStatus.authorized) return;

    final tokenDis = await messaging.getToken();
    print('TOKEN = $tokenDis');
  }

  void _handleRemoveMessage(RemoteMessage remoteMessage) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${remoteMessage.data}');

    if (remoteMessage.notification == null) return;
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(_handleRemoveMessage);
  }

  void requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
    add(NotificationStatusChanged(settings.authorizationStatus));
    _getFCMToken();
  }
}
