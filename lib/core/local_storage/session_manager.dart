import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyOrgId = 'org_id';
  static const String _keyUserId = 'user_id';
  static const String _keyRole = 'user_role';
  static const String _keyUserName = 'user_name';

  static Future<void> saveSession({
    required String organizationId,
    required String userId,
    required String role,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOrgId, organizationId);
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyUserName, userName);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyOrgId);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyRole);
    await prefs.remove(_keyUserName);
  }

  static Future<String?> get organizationId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOrgId);
  }

  static Future<String?> get userId async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  static Future<String?> get role async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRole);
  }

  static Future<String?> get userName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }
}
