import 'package:hive_flutter/hive_flutter.dart';
// Xử lý đăng nhập, đăng ký, đăng xuất người dùng
// Dữ liệu được lưu persistent trong Hive — không mất khi tắt app
class AuthService {
  static const _usersBox    = 'users';
  static const _sessionBox  = 'session';      // ✅ box riêng lưu session
  static const _sessionKey  = 'logged_in_uid';

  static Box get _users   => Hive.box(_usersBox);
  static Box get _session => Hive.box(_sessionBox);

  // ── Đăng ký ───────────────────────────────────────────────────────────────
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final list = _getUserList();
    final exists = list.any(
          (u) => (u as Map)['email'].toString().toLowerCase() ==
          email.trim().toLowerCase(),
    );
    if (exists) return 'Email này đã được đăng ký!';

    final uid = DateTime.now().millisecondsSinceEpoch.toString();
    final newUser = {
      'id'       : uid,
      'name'     : name,
      'email'    : email.trim().toLowerCase(),
      'password' : password,
      'createdAt': DateTime.now().toIso8601String(),
      'avatarUrl': '',
    };

    list.add(newUser);
    await _users.put('userList', list);

    // ✅ Lưu session ngay sau đăng ký
    await _session.put(_sessionKey, uid);
    return null;
  }

  // ── Đăng nhập ─────────────────────────────────────────────────────────────
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    final list = _getUserList();
    final user = list.cast<Map>().firstWhere(
          (u) =>
      u['email'].toString().toLowerCase() ==
          email.trim().toLowerCase() &&
          u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) return 'Email hoặc mật khẩu không đúng!';

    // ✅ Lưu uid vào session — tồn tại sau khi tắt app
    await _session.put(_sessionKey, user['id']);
    return null;
  }

  // ── Đăng xuất ─────────────────────────────────────────────────────────────
  static Future<void> logout() async {
    await _session.delete(_sessionKey);
  }

  // ── Kiểm tra đăng nhập (đọc từ session box) ───────────────────────────────
  // Gọi được ngay sau Hive.init() mà không cần await
  static bool get isLoggedIn => _session.get(_sessionKey) != null;

  // UID của user đang đăng nhập
  static String? get uid => _session.get(_sessionKey) as String?;

  // ── Lấy thông tin user hiện tại ───────────────────────────────────────────
  static Map<String, dynamic>? get currentUser {
    final id = uid;
    if (id == null) return null;
    final list = _getUserList();
    final found = list.cast<Map>().firstWhere(
          (u) => u['id'] == id,
      orElse: () => {},
    );
    if (found.isEmpty) return null;
    return Map<String, dynamic>.from(found);
  }

  // ── Cập nhật profile ──────────────────────────────────────────────────────
  static Future<void> updateProfile({
    required String name,
    required String email,
  }) async {
    final id = uid;
    if (id == null) return;

    final list = _getUserList();
    final index = list.indexWhere((u) => (u as Map)['id'] == id);
    if (index == -1) return;

    final user = Map<String, dynamic>.from(list[index] as Map);
    user['name']  = name;
    user['email'] = email.trim().toLowerCase();
    list[index]   = user;
    await _users.put('userList', list);
  }

  // ── Đổi mật khẩu ─────────────────────────────────────────────────────────
  static Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final id = uid;
    if (id == null) return 'Chưa đăng nhập!';

    final list  = _getUserList();
    final index = list.indexWhere((u) => (u as Map)['id'] == id);
    if (index == -1) return 'Không tìm thấy tài khoản!';

    final user = Map<String, dynamic>.from(list[index] as Map);
    if (user['password'] != oldPassword) return 'Mật khẩu cũ không đúng!';

    user['password'] = newPassword;
    list[index]      = user;
    await _users.put('userList', list);
    return null;
  }

  // ── Quên mật khẩu — trả về mật khẩu theo email ───────────────────────────
  static Future<String?> getPasswordByEmail(String email) async {
    final list = _getUserList();
    final user = list.cast<Map>().firstWhere(
          (u) =>
      u['email'].toString().toLowerCase() ==
          email.trim().toLowerCase(),
      orElse: () => {},
    );
    if (user.isEmpty) return null;
    return user['password'] as String?;
  }

  // ── Helper nội bộ ─────────────────────────────────────────────────────────
  static List _getUserList() =>
      (_users.get('userList', defaultValue: <dynamic>[]) as List)
          .toList(); // tạo copy tránh mutate Hive trực tiếp
}