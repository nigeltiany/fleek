enum NotificationType {
  MATCH,
  MESSAGE,
  UNKNOWN,
}

extension NotificationTypeToString on NotificationType {
  String toDataString() {
    return this.toString().split('.').last;
  }
}

NotificationType notificationTypeFromDataString(String pref) {
  for (NotificationType option in NotificationType.values) {
    if (option.toDataString() == pref) {
      return option;
    }
  }
  return NotificationType.UNKNOWN;
}

class FleekNotification {

  final String senderUserID;
  final NotificationType notificationType;

  FleekNotification({
    this.notificationType = NotificationType.UNKNOWN,
    this.senderUserID
  });

  factory FleekNotification.fromMap(Map<String, dynamic> message) {
    if (!message.containsKey("data")) {
      return FleekNotification();
    }
    return FleekNotification(
      notificationType: notificationTypeFromDataString(message["data"]["type"]),
      senderUserID: message["data"]["fromUserID"]
    );
  }

  Map<String, dynamic> debug_Jsonify() {
    return {
      "senderUserID": this.senderUserID,
      "type": this.notificationType.toDataString(),
    };
  }

}