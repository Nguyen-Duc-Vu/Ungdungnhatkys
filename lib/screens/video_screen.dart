import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:path_provider/path_provider.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import 'package:uuid/uuid.dart';

// ── Màn hình quay video màn hình ─────────────────────────────────────────────
//
// pubspec.yaml cần thêm:
//   flutter_screen_recording: ^1.0.3
//   path_provider: ^2.1.2
//   uuid: ^4.3.3
//
// Android: thêm vào AndroidManifest.xml
//   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//
// iOS: thêm vào Info.plist
//   NSMicrophoneUsageDescription → "Dùng để quay video màn hình"
//   NSPhotoLibraryUsageDescription → "Lưu video vào thư viện"
//
class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  bool _isRecording = false;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  String? _savedVideoPath;

  // ── Bắt đầu quay ───────────────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        'screen_${DateTime.now().millisecondsSinceEpoch}';

    final started = await FlutterScreenRecording.startRecordScreenAndAudio(
      fileName,
      titleNotification: 'Đang quay nhật ký',
      messageNotification: 'Nhấn dừng để lưu lại',
    );

    if (!started) {
      _showSnack('Không thể bắt đầu quay. Vui lòng cấp quyền!');
      return;
    }

    _elapsed = Duration.zero;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });

    setState(() {
      _isRecording = true;
      _savedVideoPath = null;
    });
  }

  // ── Dừng quay & lưu ────────────────────────────────────────────────────────
  Future<void> _stopRecording() async {
    _timer?.cancel();

    final path = await FlutterScreenRecording.stopRecordScreen;

    setState(() {
      _isRecording = false;
      _savedVideoPath = path;
    });

    if (path != null && path.isNotEmpty) {
      _showSnack('Video đã lưu!');
    } else {
      _showSnack('Lỗi khi lưu video.');
    }
  }

  // ── Lưu vào nhật ký ────────────────────────────────────────────────────────
  Future<void> _saveToJournal() async {
    if (_savedVideoPath == null) return;

    final entry = DiaryEntry(
      id: const Uuid().v4(),
      title: 'Video màn hình',
      content: 'Đã quay ${_formatDuration(_elapsed)}',
      mood: '🎬',
      date: DateTime.now(),
      videoPath: _savedVideoPath,
    );

    await HiveService.addEntry(entry);
    _showSnack('Đã lưu vào nhật ký!');

    if (mounted) Navigator.pop(context);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);
    const accent = Color(0xFFB5835A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Quay video màn hình',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // ── Vòng tròn trạng thái ────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording
                      ? const Color(0xFFE57373).withValues(alpha: 0.12)
                      : accent.withValues(alpha: 0.10),
                  border: Border.all(
                    color: _isRecording
                        ? const Color(0xFFE57373).withValues(alpha: 0.4)
                        : accent.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _isRecording
                        ? Icons.radio_button_checked_rounded
                        : Icons.videocam_rounded,
                    size: 64,
                    color: _isRecording
                        ? const Color(0xFFE57373)
                        : accent,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Bộ đếm thời gian ───────────────────────────────────────
              Text(
                _formatDuration(_elapsed),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: _isRecording
                      ? const Color(0xFFE57373)
                      : (isDark ? Colors.white : const Color(0xFF2C1810)),
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _isRecording
                    ? 'Đang quay...'
                    : _savedVideoPath != null
                    ? 'Đã quay xong ✓'
                    : 'Nhấn để bắt đầu quay',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),

              const Spacer(),

              // ── Nút chính ──────────────────────────────────────────────
              GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isRecording
                          ? [
                        const Color(0xFFE57373),
                        const Color(0xFFEF5350),
                      ]
                          : [
                        const Color(0xFFB5835A),
                        const Color(0xFF8B5E3C),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording
                            ? const Color(0xFFE57373)
                            : accent)
                            .withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.fiber_manual_record_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isRecording ? 'Dừng quay' : 'Bắt đầu quay',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Nút lưu vào nhật ký (hiện sau khi quay xong) ──────────
              AnimatedOpacity(
                opacity: _savedVideoPath != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: GestureDetector(
                  onTap: _savedVideoPath != null ? _saveToJournal : null,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.save_rounded,
                            color: accent,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Lưu vào nhật ký',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}