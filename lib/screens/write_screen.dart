import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import '../models/diary_entry.dart';

class WriteScreen extends StatefulWidget {
  const WriteScreen({super.key});

  @override
  State<WriteScreen> createState() => _WriteScreenState();
}

class _WriteScreenState extends State<WriteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = '😊';
  File? _imageFile;
  File? _videoFile;
  final _picker = ImagePicker();

  final List<Map<String, String>> _moods = [
    {'emoji': '😊', 'label': 'Vui'},
    {'emoji': '🥰', 'label': 'Yêu'},
    {'emoji': '😎', 'label': 'Cool'},
    {'emoji': '🤔', 'label': 'Suy nghĩ'},
    {'emoji': '😴', 'label': 'Mệt'},
    {'emoji': '😢', 'label': 'Buồn'},
    {'emoji': '😡', 'label': 'Tức'},
    {'emoji': '😰', 'label': 'Lo lắng'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<void> _openVideoRecorder() async {
    final result = await Navigator.push<File?>(
      context,
      MaterialPageRoute(builder: (_) => const _InlineVideoRecorder()),
    );
    if (result != null && mounted) {
      setState(() => _videoFile = result);
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: _iconBox(Icons.camera_alt_rounded),
                title: const Text('Chụp ảnh',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: _iconBox(Icons.photo_library_rounded),
                title: const Text('Thư viện ảnh',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: _iconBox(Icons.videocam_rounded),
                title: const Text('Quay video',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Ghi lại khoảnh khắc bằng video',
                    style: TextStyle(fontSize: 12)),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (!mounted) return;
                  await _openVideoRecorder();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBox(IconData icon) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFB5835A).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: const Color(0xFFB5835A)),
  );

  void _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Vui lòng nhập tiêu đề!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    String? savedImagePath;
    if (_imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(_imageFile!.path);
      final saved = await _imageFile!.copy('${appDir.path}/$fileName');
      savedImagePath = saved.path;
    }

    String? savedVideoPath;
    if (_videoFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = p.basename(_videoFile!.path);
      final saved = await _videoFile!.copy('${appDir.path}/$fileName');
      savedVideoPath = saved.path;
    }

    final entry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      mood: _selectedMood,
      date: DateTime.now(),
      isFavorite: false,
      imagePath: savedImagePath,
      videoPath: savedVideoPath,
    );

    if (mounted) Navigator.pop(context, entry);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.arrow_back_rounded,
                size: 18,
                color: isDark ? Colors.white : const Color(0xFF2C1810)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Viết nhật ký',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF2C1810),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB5835A).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Text(
                  'Lưu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hôm nay bạn cảm thấy thế nào?',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.grey.shade600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _moods.length,
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMood == mood['emoji'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedMood = mood['emoji']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      width: 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFB5835A)
                            : isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFB5835A)
                              : isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : const Color(0xFFEDE5D8),
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: const Color(0xFFB5835A)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                            : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mood['emoji']!,
                              style: const TextStyle(fontSize: 22)),
                          const SizedBox(height: 2),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              fontSize: 9,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            _buildLabel('Tiêu đề', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF2C1810),
              ),
              decoration: _inputDecoration('Nhập tiêu đề...', isDark),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            _buildLabel('Nội dung', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF4A3728),
                height: 1.7,
              ),
              decoration: _inputDecoration('Viết gì đó hôm nay...', isDark),
              maxLines: 8,
              minLines: 5,
            ),

            const SizedBox(height: 24),

            _buildLabel('Ảnh & Video đính kèm', isDark),
            const SizedBox(height: 12),

            if (_imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageFile = null),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            if (_videoFile != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFB5835A).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB5835A).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Video đã quay',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFFB5835A),
                            ),
                          ),
                          Text(
                            p.basename(_videoFile!.path),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _videoFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.red, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            GestureDetector(
              onTap: _showImagePicker,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFB5835A).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFB5835A).withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_rounded,
                        color: Color(0xFFB5835A), size: 22),
                    SizedBox(width: 8),
                    Icon(Icons.videocam_rounded,
                        color: Color(0xFFB5835A), size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Thêm ảnh hoặc quay video',
                      style: TextStyle(
                        color: Color(0xFFB5835A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark
            ? Colors.white.withValues(alpha: 0.5)
            : Colors.grey.shade600,
        letterSpacing: 0.3,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor:
      isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEDE5D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFEDE5D8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFB5835A), width: 2),
      ),
      counterStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11),
    );
  }
}

// ══════════════════════════════════════════════════════════
// Màn hình quay video
// ══════════════════════════════════════════════════════════

class _InlineVideoRecorder extends StatefulWidget {
  const _InlineVideoRecorder();

  @override
  State<_InlineVideoRecorder> createState() => _InlineVideoRecorderState();
}

class _InlineVideoRecorderState extends State<_InlineVideoRecorder> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isSaving = false;
  int _cameraIndex = 0;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    await Permission.camera.request();
    await Permission.microphone.request();

    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _isRecording) return;

    _cameraIndex = _cameraIndex == 0 ? 1 : 0;
    await _controller?.dispose();

    _controller = CameraController(
      _cameras[_cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (_isRecording) {
      final file = await _controller!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _isSaving = true;
      });

      await SaverGallery.saveFile(
        filePath: file.path,
        fileName: p.basename(file.path),
        skipIfExists: false,
        androidRelativePath: 'Movies/Nhat Ky',
      );

      setState(() => _isSaving = false);
      if (mounted) Navigator.pop(context, File(file.path));
    } else {
      await _controller!.startVideoRecording();
      setState(() => _isRecording = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quay video nhật ký',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFB5835A)),
      )
          : Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),

          if (_isRecording)
            Positioned(
              top: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, color: Colors.white, size: 10),
                      SizedBox(width: 6),
                      Text(
                        'Đang quay...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _flipCamera,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.flip_camera_ios_rounded,
                  color: _isRecording ? Colors.white38 : Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _isSaving ? null : _toggleRecording,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red
                          : const Color(0xFFB5835A),
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                              ? Colors.red
                              : const Color(0xFFB5835A))
                              .withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: _isSaving
                        ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Icon(
                      _isRecording
                          ? Icons.stop_rounded
                          : Icons.videocam_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _isSaving
                      ? 'Đang lưu...'
                      : _isRecording
                      ? 'Nhấn để dừng & lưu vào nhật ký'
                      : 'Nhấn để bắt đầu quay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}