import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_app/domain/entities/push_message.dart';
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
  int pushNumber = 0;
  final Future<void> Function()? requestLocalNotificationPermissions;
  final void Function({
    required int id,
    String? title,
    String? body,
    String? data,
  })? showLocalNotification;

  NotificationsBloc(
      {this.requestLocalNotificationPermissions, this.showLocalNotification})
      : super(const NotificationsState()) {
    on<NotificationStatusChanged>(_notificationStatusChanged);
    on<NotificationReceived>(_onPushMessageRecived);
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

  void _onPushMessageRecived(
      NotificationReceived event, Emitter<NotificationsState> emit) {
    emit(state
        .copyWith(notifications: [event.notification, ...state.notifications]));
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

  void handleRemoveMessage(RemoteMessage remoteMessage) {
    if (remoteMessage.notification == null) return;

    final notification = PushMessage(
        messageId:
            remoteMessage.messageId?.replaceAll(':', '').replaceAll('%', '') ??
                '',
        title: remoteMessage.notification!.title ?? '',
        body: remoteMessage.notification!.body ?? '',
        sentDate: remoteMessage.sentTime ?? DateTime.now(),
        data: remoteMessage.data,
        imageUrl: Platform.isAndroid
            ? remoteMessage.notification!.android?.imageUrl
            : remoteMessage.notification!.apple?.imageUrl);

    if (showLocalNotification != null) {
      showLocalNotification!(
          id: ++pushNumber,
          body: notification.body,
          title: notification.title,
          data: notification.messageId);
    }

    add(NotificationReceived(notification));
  }

  void _onForegroundMessage() {
    FirebaseMessaging.onMessage.listen(handleRemoveMessage);
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

    if (requestLocalNotificationPermissions != null) {
      await requestLocalNotificationPermissions!();
    }

    add(NotificationStatusChanged(settings.authorizationStatus));
    _getFCMToken();
  }

  PushMessage? getMessageById(String pushMessageId) {
    final exits = state.notifications.any(
      (element) => element.messageId == pushMessageId,
    );

    if (!exits) return null;

    return state.notifications.firstWhere(
      (element) => element.messageId == pushMessageId,
    );
  }
}
