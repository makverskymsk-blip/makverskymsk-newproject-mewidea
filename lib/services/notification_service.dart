import 'package:new_idea_works/utils/app_logger.dart';
import 'package:flutter/material.dart';

class NotificationService {
  // FCM was removed during Supabase migration.
  // To restore push notifications, you can use:
  // 1. OneSignal (onesignal_flutter)
  // 2. Keep FCM by re-adding firebase_messaging (recommended for standard push)
  // 3. Supabase edge functions with an HTTP push provider.

  /// Placeholder for initialization.
  Future<String?> initialize() async {
    appLog('Notifications: Firebase Messaging was removed. Migration to another provider required.');
    return null;
  }

  /// Subscribe to community topic (placeholder).
  Future<void> subscribeToCommunity(String communityId) async {
    appLog('Notifications: Subscribe attempt to $communityId (FCM disabled)');
  }

  /// Unsubscribe from community topic (placeholder).
  Future<void> unsubscribeFromCommunity(String communityId) async {
    appLog('Notifications: Unsubscribe attempt from $communityId (FCM disabled)');
  }
}
