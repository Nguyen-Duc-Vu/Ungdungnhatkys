import 'package:hive_flutter/hive_flutter.dart';
import '../models/diary_entry.dart';
import 'auth_service.dart';
// Quản lý lưu trữ dữ liệu bằng Hive (thêm, sửa, xóa nhật ký)
// Mỗi user có box riêng theo uid → đăng nhập lại vẫn còn đủ data
class HiveService {
  static const String _baseBoxName = 'diary_entries';

  static String get _boxName {
    final uid = AuthService.uid;
    return uid != null ? '${_baseBoxName}_$uid' : _baseBoxName;
  }

  static Box<DiaryEntry>? _box;
  static String? _currentBoxName;

  // ── Khởi tạo (gọi 1 lần trong main) ──────────────────────────────────────
  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(DiaryEntryAdapter());
  }

  // ── Mở box cho user hiện tại ──────────────────────────────────────────────
  static Future<Box<DiaryEntry>> _ensureBox() async {
    final name = _boxName;
    if (_box == null || !_box!.isOpen || _currentBoxName != name) {
      if (_box != null && _box!.isOpen && _currentBoxName != name) {
        await _box!.close();
      }
      _box = await Hive.openBox<DiaryEntry>(name);
      _currentBoxName = name;
    }
    return _box!;
  }

  // ── Gọi sau đăng nhập / đăng xuất để switch box ──────────────────────────
  static Future<void> switchUser() async {
    if (_box != null && _box!.isOpen) await _box!.close();
    _box = null;
    _currentBoxName = null;
    if (AuthService.isLoggedIn) await _ensureBox();
  }

  // ── Getter box cho ValueListenableBuilder ─────────────────────────────────
  static Box<DiaryEntry> get box {
    if (_box != null && _box!.isOpen) return _box!;
    throw Exception('HiveService.box chưa mở. Gọi switchUser() sau login.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SYNC methods — dùng trong setState / build / ValueListenableBuilder
  // An toàn vì box đã được _ensureBox() mở sẵn sau khi login
  // ─────────────────────────────────────────────────────────────────────────

  static List<DiaryEntry> getAllEntries() {
    if (_box == null || !_box!.isOpen) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  static List<DiaryEntry> getFavorites() {
    if (_box == null || !_box!.isOpen) return [];
    return _box!.values.where((e) => e.isFavorite).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<DiaryEntry> searchSync(String query) {
    if (_box == null || !_box!.isOpen) return [];
    final q = query.toLowerCase();
    return _box!.values
        .where((e) =>
    e.title.toLowerCase().contains(q) ||
        e.content.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ASYNC methods — dùng trong initState, button handlers
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> addEntry(DiaryEntry entry) async {
    final b = await _ensureBox();
    await b.put(entry.id, entry);
  }

  static Future<void> updateEntry(DiaryEntry entry) async {
    await _ensureBox();
    await entry.save();
  }

  static Future<void> deleteEntry(String id) async {
    final b = await _ensureBox();
    await b.delete(id);
  }
}