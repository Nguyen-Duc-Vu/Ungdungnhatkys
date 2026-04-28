import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
//Chỉnh sửa nội dung bài nhật ký
class EditScreen extends StatefulWidget {
  final DiaryEntry entry;
  const EditScreen({super.key, required this.entry});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late String _selectedMood;
  File? _imageFile;
  String? _existingImagePath;
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
  void initState() {
    super.initState();
    // Load dữ liệu cũ vào form
    _titleController =
        TextEditingController(text: widget.entry.title);
    _contentController =
        TextEditingController(text: widget.entry.content);
    _selectedMood = widget.entry.mood;
    _existingImagePath = widget.entry.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
        source: source, imageQuality: 80);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _existingImagePath = null; // xóa ảnh cũ
      });
    }
  }

  void _showImagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2420) : Colors.white,
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
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: _iconBox(Icons.photo_library_rounded),
                title: const Text('Thư viện ảnh',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_existingImagePath != null || _imageFile != null)
                ListTile(
                  leading: _iconBox(Icons.delete_outline_rounded),
                  title: const Text('Xóa ảnh',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _imageFile = null;
                      _existingImagePath = null;
                    });
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
          backgroundColor: const Color(0xFFB5835A),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    String? savedImagePath = _existingImagePath;

    // Nếu chọn ảnh mới thì lưu ảnh mới
    if (_imageFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(_imageFile!.path)}';
      final saved =
      await _imageFile!.copy('${appDir.path}/$fileName');
      savedImagePath = saved.path;
    }

    // Cập nhật entry
    widget.entry.title = _titleController.text.trim();
    widget.entry.content = _contentController.text.trim();
    widget.entry.mood = _selectedMood;
    widget.entry.imagePath = savedImagePath;

    await HiveService.updateEntry(widget.entry);

    if (mounted) Navigator.pop(context, 'updated');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
    isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);

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
                color: isDark
                    ? Colors.white
                    : const Color(0xFF2C1810)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa nhật ký',
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
                      color: const Color(0xFFB5835A)
                          .withValues(alpha: 0.4),
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
            // Mood
            _buildLabel('Cảm xúc', isDark),
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
                    onTap: () => setState(
                            () => _selectedMood = mood['emoji']!),
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
                              ? Colors.white
                              .withValues(alpha: 0.1)
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

            // Tiêu đề
            _buildLabel('Tiêu đề', isDark),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                isDark ? Colors.white : const Color(0xFF2C1810),
              ),
              decoration: _inputDecoration('Nhập tiêu đề...', isDark),
              maxLength: 100,
            ),

            const SizedBox(height: 16),

            // Nội dung
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
              decoration:
              _inputDecoration('Viết gì đó hôm nay...', isDark),
              maxLines: 8,
              minLines: 5,
            ),

            const SizedBox(height: 24),

            // Ảnh
            _buildLabel('Ảnh đính kèm', isDark),
            const SizedBox(height: 12),

            // Hiển thị ảnh hiện tại hoặc ảnh mới chọn
            if (_imageFile != null || _existingImagePath != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _imageFile != null
                        ? Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      File(_existingImagePath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: Colors.grey, size: 40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _imageFile = null;
                          _existingImagePath = null;
                        }),
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

            // Nút chọn ảnh
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
                    color: const Color(0xFFB5835A)
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_photo_alternate_rounded,
                        color: Color(0xFFB5835A), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      _imageFile != null || _existingImagePath != null
                          ? 'Đổi ảnh'
                          : 'Thêm ảnh',
                      style: const TextStyle(
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
      hintStyle:
      TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.white,
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
        borderSide:
        const BorderSide(color: Color(0xFFB5835A), width: 2),
      ),
      counterStyle:
      TextStyle(color: Colors.grey.shade400, fontSize: 11),
    );
  }
}