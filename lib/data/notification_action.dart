/// FCM data values are `dynamic`. A missing `action` is an empty string so
/// the redirect's `isEmpty` check can run.
String notificationActionValue(Object? action) => action?.toString() ?? '';
