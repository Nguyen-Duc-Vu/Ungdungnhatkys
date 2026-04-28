import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';

class DetailScreen extends StatefulWidget {
  final DiaryEntry entry;
  const DetailScreen({super.key, required this.entry});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoPath = widget.entry.videoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(videoPath));
      await _videoController!.initialize();
      _videoController!.addListener(() {
        if (mounted) setState(() {});
      });
      setState(() => _videoInitialized = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);
    final entry = widget.entry;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white : const Color(0xFF2C1810)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFB5835A).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.edit_rounded, size: 18, color: Color(0xFFB5835A)),
            ),
            onPressed: () async {
              final result = await Navigator.pushNamed(context, AppRoutes.edit, arguments: entry);
              if (result == 'updated' && mounted) Navigator.pop(context, 'updated');
            },
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Xóa nhật ký?'),
                  content: const Text('Hành động này không thể hoàn tác.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Xóa', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await HiveService.deleteEntry(entry.id);
                if (mounted) Navigator.pop(context, 'deleted');
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFB5835A).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(entry.mood, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(entry.date), style: const TextStyle(fontSize: 13, color: Color(0xFFB5835A), fontWeight: FontWeight.bold)),
                    Text('${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(entry.title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF2C1810))),
            const SizedBox(height: 16),
            Text(entry.content.isEmpty ? '(Không có nội dung)' : entry.content, style: TextStyle(fontSize: 16, height: 1.8, color: isDark ? Colors.white70 : const Color(0xFF4A3728))),

            if (entry.imagePath != null && entry.imagePath!.isNotEmpty) ...[
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(File(entry.imagePath!), fit: BoxFit.cover, width: double.infinity),
              ),
            ],

            // PHẦN VIDEO HÌNH VUÔNG 1:1
            if (entry.videoPath != null && entry.videoPath!.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text('Video đính kèm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white54 : Colors.grey.shade700)),
              const SizedBox(height: 16),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8, // Chiều rộng bằng 80% màn hình
                  ),
                  child: _videoInitialized && _videoController != null
                      ? _buildVideoPlayer(isDark)
                      : const AspectRatio(
                    aspectRatio: 1 / 1,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFB5835A))),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(bool isDark) {
    final controller = _videoController!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20), // Bo góc tròn hơn cho đẹp
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: AspectRatio(
              aspectRatio: 1 / 1, // ÉP VỀ HÌNH VUÔNG
              child: Stack(
                alignment: Alignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.cover, // Cắt bớt phần thừa để lấp đầy hình vuông, không để khoảng đen
                    child: SizedBox(
                      width: controller.value.size.width,
                      height: controller.value.size.height,
                      child: VideoPlayer(controller),
                    ),
                  ),
                  if (!controller.value.isPlaying)
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.white, size: 50),
                      onPressed: () => setState(() => controller.play()),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(_formatDuration(controller.value.position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => controller.value.isPlaying ? controller.pause() : controller.play()),
                  child: Icon(controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: const Color(0xFFB5835A), size: 30),
                ),
                const Spacer(),
                Text(_formatDuration(controller.value.duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}