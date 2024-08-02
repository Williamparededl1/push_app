part of 'notifications_bloc.dart';

class NotificationsState extends Equatable {
  final AuthorizationStatus status;
  //Todo: Crear el  modelo de la notificacion
  final List<dynamic> notifications;
  const NotificationsState(
      {this.status = AuthorizationStatus.notDetermined,
      this.notifications = const []});

  NotificationsState copyWith(
          {AuthorizationStatus? status, List<dynamic>? notifications}) =>
      NotificationsState(
          status: status ?? this.status,
          notifications: notifications ?? this.notifications);

  @override
  List<Object> get props => [status, notifications];
}
