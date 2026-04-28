import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../providers/theme_provider.dart';
import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../models/diary_entry.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _reminderEnabled = false;
  // ✅ Dùng DateTime thay vì TimeOfDay để lưu cả ngày lẫn giờ
  DateTime _reminderDateTime = DateTime.now().copyWith(hour: 21, minute: 0, second: 0, millisecond: 0, microsecond: 0);
  String _name = 'Nguyễn Văn A';
  String _email = 'email@gmail.com';
  String? _avatarPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final box = Hive.box('settings');
      setState(() {
        _reminderEnabled = box.get('reminderEnabled', defaultValue: false);
        final now = DateTime.now();
        final hour = box.get('reminderHour', defaultValue: 21);
        final minute = box.get('reminderMinute', defaultValue: 0);
        // ✅ Load ngày đã lưu (nếu có), không thì dùng ngày hiện tại
        final savedDay = box.get('reminderDay', defaultValue: now.day);
        final savedMonth = box.get('reminderMonth', defaultValue: now.month);
        final savedYear = box.get('reminderYear', defaultValue: now.year);
        _reminderDateTime = DateTime(savedYear, savedMonth, savedDay, hour, minute);
        _avatarPath = box.get('avatarPath');
      });
      final user = AuthService.currentUser;
      if (user != null) {
        _name = user['name'] ?? 'Nguyễn Văn A';
        _email = user['email'] ?? 'email@gmail.com';
      }
    } catch (_) {}
  }

  // ✅ Format hiển thị ngày + giờ đẹp tiếng Việt
  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dtDate = DateTime(dt.year, dt.month, dt.day);

    String dateLabel;
    if (dtDate == today) {
      dateLabel = 'Hôm nay';
    } else if (dtDate == tomorrow) {
      dateLabel = 'Ngày mai';
    } else {
      dateLabel = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    }

    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$dateLabel lúc $hour:$minute';
  }

  Future<void> _pickAvatar() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20)),
        child: SafeArea(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12, bottom: 8), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            ListTile(leading: _iconBox(Icons.camera_alt_rounded), title: const Text('Chụp ảnh', style: TextStyle(fontWeight: FontWeight.w600)), onTap: () { Navigator.pop(context); _saveAvatar(ImageSource.camera); }),
            ListTile(leading: _iconBox(Icons.photo_library_rounded), title: const Text('Chọn từ thư viện', style: TextStyle(fontWeight: FontWeight.w600)), onTap: () { Navigator.pop(context); _saveAvatar(ImageSource.gallery); }),
            if (_avatarPath != null)
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.delete_outline_rounded, color: Colors.red)),
                title: const Text('Xóa ảnh đại diện', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () async { Navigator.pop(context); final box = Hive.box('settings'); await box.delete('avatarPath'); setState(() => _avatarPath = null); },
              ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFFB5835A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFFB5835A)));

  Future<void> _saveAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'avatar_${p.basename(picked.path)}';
    final saved = await File(picked.path).copy('${appDir.path}/$fileName');
    final box = Hive.box('settings');
    await box.put('avatarPath', saved.path);
    setState(() => _avatarPath = saved.path);
  }

  void _editProfile() {
    final nameCtrl = TextEditingController(text: _name);
    final emailCtrl = TextEditingController(text: _email);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF2A2420) : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
            const SizedBox(height: 20),
            Text('Tên hiển thị', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: nameCtrl, decoration: _inputDeco('Nhập tên...', isDark)),
            const SizedBox(height: 16),
            Text('Email', style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: _inputDeco('Nhập email...', isDark)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () async {
                  final newName = nameCtrl.text.trim();
                  final newEmail = emailCtrl.text.trim();
                  if (newName.isEmpty) return;
                  await AuthService.updateProfile(name: newName, email: newEmail);
                  setState(() { _name = newName; _email = newEmail; });
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)]), borderRadius: BorderRadius.circular(14)),
                  child: const Center(child: Text('Lưu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, bool isDark) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400),
    filled: true,
    fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFFAF7F2),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFB5835A), width: 1.5)),
  );

  Future<void> _toggleReminder(bool value) async {
    try {
      final box = Hive.box('settings');
      if (value) {
        // ✅ Nếu bật, mở picker chọn ngày + giờ luôn
        final picked = await _showDateTimePicker(_reminderDateTime);
        if (picked == null) return; // user bấm hủy → không bật
        setState(() => _reminderDateTime = picked);
        await _saveReminderDateTime(picked);
        await NotificationService.scheduleReminder(dateTime: picked);
      } else {
        await NotificationService.cancelAll();
      }
      await box.put('reminderEnabled', value);
      setState(() => _reminderEnabled = value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(value ? '✅ Đã đặt nhắc nhở: ${_formatDateTime(_reminderDateTime)}' : '🔕 Đã tắt nhắc nhở'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFB5835A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  // ✅ Hàm hiện bottom sheet chọn ngày + giờ đẹp
  Future<DateTime?> _showDateTimePicker(DateTime initial) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bước 1: chọn ngày
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('vi', 'VN'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFFB5835A),
            onPrimary: Colors.white,
            surface: isDark ? const Color(0xFF2A2420) : Colors.white,
            onSurface: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
          dialogBackgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return null;

    // Bước 2: chọn giờ
    if (!mounted) return null;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: const Color(0xFFB5835A),
            onPrimary: Colors.white,
            surface: isDark ? const Color(0xFF2A2420) : Colors.white,
            onSurface: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
          dialogBackgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return null;

    return DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
  }

  // ✅ Chỉnh sửa lịch nhắc đã bật
  Future<void> _editReminderDateTime() async {
    final picked = await _showDateTimePicker(_reminderDateTime);
    if (picked == null) return;
    setState(() => _reminderDateTime = picked);
    await _saveReminderDateTime(picked);
    if (_reminderEnabled) {
      await NotificationService.scheduleReminder(dateTime: picked);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Đã cập nhật: ${_formatDateTime(picked)}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB5835A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _saveReminderDateTime(DateTime dt) async {
    final box = Hive.box('settings');
    await box.put('reminderHour', dt.hour);
    await box.put('reminderMinute', dt.minute);
    await box.put('reminderDay', dt.day);
    await box.put('reminderMonth', dt.month);
    await box.put('reminderYear', dt.year);
  }

  Future<void> _testNotification() async {
    try {
      await NotificationService.sendTestNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('📤 Đã gửi! Kéo thanh thông báo xuống để xem.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);

    return ValueListenableBuilder(
      valueListenable: HiveService.box.listenable(),
      builder: (context, box, _) {
        final List<DiaryEntry> entries = HiveService.getAllEntries();
        final favorites = entries.where((e) => e.isFavorite).length;
        final writtenDays = entries.map((e) => DateTime(e.date.year, e.date.month, e.date.day)).toSet().length;

        return Scaffold(
          backgroundColor: bg,
          body: CustomScrollView(slivers: [
            SliverToBoxAdapter(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark ? [const Color(0xFF3D2B1A), const Color(0xFF2A1F14)] : [const Color(0xFFB5835A), const Color(0xFF8B5E3C)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                child: Column(children: [
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                          image: _avatarPath != null ? DecorationImage(image: FileImage(File(_avatarPath!)), fit: BoxFit.cover) : null,
                        ),
                        child: _avatarPath == null ? const Icon(Icons.person_rounded, size: 46, color: Colors.white) : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: const Color(0xFF8B5E3C), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white))),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(_name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(_email, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _ProfileStat(value: '${entries.length}', label: 'Bài viết'),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _ProfileStat(value: '$favorites', label: 'Yêu thích'),
                    Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.3), margin: const EdgeInsets.symmetric(horizontal: 24)),
                    _ProfileStat(value: '$writtenDays', label: 'Ngày viết'),
                  ]),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionLabel('Cài đặt'),
                  const SizedBox(height: 12),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingsTile(
                      icon: Icons.dark_mode_rounded, iconBg: const Color(0xFF5C6BC0), title: 'Chế độ tối',
                      trailing: Switch.adaptive(value: context.watch<ThemeProvider>().isDark, onChanged: (_) => context.read<ThemeProvider>().toggle(), activeColor: const Color(0xFFB5835A)),
                      isDark: isDark,
                    ),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.notifications_rounded, iconBg: const Color(0xFFEF6C00), title: 'Nhắc nhở viết nhật ký',
                      // ✅ Hiển thị ngày + giờ đầy đủ
                      subtitle: _reminderEnabled
                          ? _formatDateTime(_reminderDateTime)
                          : 'Chưa bật',
                      trailing: Switch.adaptive(value: _reminderEnabled, onChanged: _toggleReminder, activeColor: const Color(0xFFB5835A)),
                      isDark: isDark,
                    ),
                    if (_reminderEnabled) ...[
                      _Divider(isDark: isDark),
                      // ✅ Tile chỉnh sửa ngày + giờ nhắc nhở
                      _SettingsTile(
                        icon: Icons.edit_calendar_rounded, iconBg: const Color(0xFF26A69A),
                        title: 'Chỉnh thời gian nhắc',
                        subtitle: _formatDateTime(_reminderDateTime),
                        onTap: _editReminderDateTime,
                        isDark: isDark,
                      ),
                    ],
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      iconBg: Colors.green,
                      title: 'Test thông báo ngay',
                      subtitle: 'Nhấn để kiểm tra notification có hoạt động không',
                      onTap: _testNotification,
                      isDark: isDark,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _SectionLabel('Tài khoản'),
                  const SizedBox(height: 12),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingsTile(icon: Icons.person_outline_rounded, iconBg: const Color(0xFFB5835A), title: 'Chỉnh sửa hồ sơ', onTap: _editProfile, isDark: isDark),
                    _Divider(isDark: isDark),
                    _SettingsTile(
                      icon: Icons.logout_rounded, iconBg: const Color(0xFFE53935), title: 'Đăng xuất', titleColor: Colors.red,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Đăng xuất?', style: TextStyle(fontWeight: FontWeight.w700)),
                            content: const Text('Bạn có chắc muốn đăng xuất không?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await AuthService.logout();
                          await HiveService.switchUser();
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                                  (_) => false,
                            );
                          }
                        }
                      },
                      isDark: isDark,
                    ),
                  ]),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value, label;
  const _ProfileStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
  ]);
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1.2));
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _SettingsCard({required this.children, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF2A2420) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDE5D8)),
      boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.2) : const Color(0xFFB5835A).withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Column(children: children),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon; final Color iconBg; final String title; final String? subtitle;
  final Color? titleColor; final Widget? trailing; final VoidCallback? onTap; final bool isDark;
  const _SettingsTile({required this.icon, required this.iconBg, required this.title, this.subtitle, this.titleColor, this.trailing, this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: Colors.white, size: 18)),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: titleColor ?? (isDark ? Colors.white : const Color(0xFF2C1810)))),
    subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)) : null,
    trailing: trailing ?? (onTap != null ? Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400) : null),
  );
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 64, endIndent: 16, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0E8DF));
}