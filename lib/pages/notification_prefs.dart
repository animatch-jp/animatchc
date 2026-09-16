import 'package:cloud_firestore/cloud_firestore.dart';

Future<bool> shouldSendNotification(String uid, String settingKey) async {
  try {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final settings = doc.data()?['notificationSettings'] as Map<String, dynamic>?;
    if (settings == null || !settings.containsKey(settingKey)) return true;
    return settings[settingKey] as bool? ?? true;
  } catch (e) {
    return true;
  }
}
