import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';

class FavoriteScreen extends StatefulWidget {
  // ✅ Nhận favorites từ HomeScreen truyền vào — luôn sync
  final List<DiaryEntry> favorites;
  final VoidCallback onDataChanged; // callback để HomeScreen reload

  const FavoriteScreen({
    super.key,
    required this.favorites,
    required this.onDataChanged,
  });

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  bool _isSelecting = false;
  final Set<String> _selected = {};

  String _formatDate(DateTime d) {
    const months = ['Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'];
    return '${d.day} ${months[d.month - 1]}, ${d.year}';
  }

  void _enterSelectMode() => setState(() { _isSelecting = true; _selected.clear(); });
  void _exitSelectMode()  => setState(() { _isSelecting = false; _selected.clear(); });
  void _toggleSelect(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });
  void _selectAll() => setState(() => _selected.addAll(widget.favorites.map((e) => e.id)));

  void _confirmClearAll() {
    _showDialog(
      title: 'Xoá tất cả yêu thích?',
      content: 'Tất cả bài viết sẽ bị bỏ khỏi danh sách yêu thích.',
      actionLabel: 'Xoá tất cả',
      onConfirm: () async {
        for (final e in widget.favorites) { e.isFavorite = false; await e.save(); }
        _exitSelectMode();
        widget.onDataChanged();
      },
    );
  }

  void _confirmRemoveSelected() {
    if (_selected.isEmpty) return;
    _showDialog(
      title: 'Bỏ ${_selected.length} bài khỏi yêu thích?',
      content: 'Các bài viết sẽ bị bỏ khỏi danh sách yêu thích.',
      actionLabel: 'Bỏ yêu thích',
      onConfirm: () async {
        for (final id in _selected.toList()) {
          try {
            final e = widget.favorites.firstWhere((e) => e.id == id);
            e.isFavorite = false;
            await e.save();
          } catch (_) {}
        }
        _exitSelectMode();
        widget.onDataChanged();
      },
    );
  }

  void _confirmDeleteSelected() {
    if (_selected.isEmpty) return;
    _showDialog(
      title: 'Xoá ${_selected.length} bài viết?',
      content: 'Hành động này không thể hoàn tác.',
      actionLabel: 'Xoá',
      isDestructive: true,
      onConfirm: () async {
        for (final id in _selected.toList()) await HiveService.deleteEntry(id);
        _exitSelectMode();
        widget.onDataChanged();
      },
    );
  }

  void _showDialog({
    required String title, required String content,
    required String actionLabel, required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
        content: Text(content, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); onConfirm(); },
            child: Text(actionLabel, style: TextStyle(color: isDestructive ? Colors.red : const Color(0xFFE57373), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2);
    final favorites = widget.favorites;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ Không hiện nút back
        title: Text(
          _isSelecting ? '${_selected.length} đã chọn' : 'Yêu thích',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20,
              color: isDark ? Colors.white : const Color(0xFF2C1810)),
        ),
        actions: [
          if (_isSelecting)
            TextButton(
              onPressed: _exitSelectMode,
              child: const Text('Xong', style: TextStyle(color: Color(0xFFB5835A), fontWeight: FontWeight.w700)),
            )
          else if (favorites.isNotEmpty)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white70 : const Color(0xFF2C1810)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              onSelected: (val) {
                if (val == 'select') _enterSelectMode();
                if (val == 'clear_all') _confirmClearAll();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'select', child: Row(children: [
                  Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFFB5835A)),
                  SizedBox(width: 10), Text('Chọn bài viết'),
                ])),
                const PopupMenuItem(value: 'clear_all', child: Row(children: [
                  Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 10), Text('Xoá tất cả', style: TextStyle(color: Colors.red)),
                ])),
              ],
            ),
        ],
      ),
      body: favorites.isEmpty ? _buildEmpty() : Stack(
        children: [
          Column(
            children: [
              if (_isSelecting)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: GestureDetector(
                    onTap: _selectAll,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.select_all_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                        const SizedBox(width: 8),
                        Text('Chọn tất cả (${favorites.length})',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54)),
                      ]),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                  itemCount: favorites.length,
                  itemBuilder: (_, i) {
                    final e = favorites[i];
                    final isSelected = _selected.contains(e.id);
                    return GestureDetector(
                      onTap: () {
                        if (_isSelecting) {
                          _toggleSelect(e.id);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.detail, arguments: e)
                              .then((_) => widget.onDataChanged());
                        }
                      },
                      onLongPress: () {
                        if (!_isSelecting) _enterSelectMode();
                        _toggleSelect(e.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFE57373).withValues(alpha: isDark ? 0.2 : 0.1)
                              : isDark ? const Color(0xFF2A2420) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE57373) : isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDE5D8),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: [BoxShadow(
                            color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFB5835A).withValues(alpha: 0.08),
                            blurRadius: 16, offset: const Offset(0, 4),
                          )],
                        ),
                        child: Row(
                          children: [
                            if (_isSelecting) ...[
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 24, height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? const Color(0xFFE57373) : Colors.transparent,
                                  border: Border.all(color: isSelected ? const Color(0xFFE57373) : Colors.grey.shade400, width: 1.5),
                                ),
                                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: const Color(0xFFE57373).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Center(child: Text(e.mood, style: const TextStyle(fontSize: 24))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF2C1810)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_formatDate(e.date), style: TextStyle(fontSize: 11, color: const Color(0xFFB5835A).withValues(alpha: 0.8))),
                              if (e.content.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(e.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ])),
                            if (!_isSelecting)
                              const Icon(Icons.favorite_rounded, color: Color(0xFFE57373), size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          if (_isSelecting)
            Positioned(
              bottom: 24, left: 32, right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2A2420) : Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEDE5D8)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ToolbarAction(icon: Icons.favorite_border_rounded, label: 'Bỏ yêu thích', color: const Color(0xFFE57373), enabled: _selected.isNotEmpty, onTap: _confirmRemoveSelected),
                    Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.black12),
                    _ToolbarAction(icon: Icons.delete_outline_rounded, label: 'Xoá', color: Colors.red, enabled: _selected.isNotEmpty, onTap: _confirmDeleteSelected),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.favorite_border_rounded, size: 72, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text('Chưa có bài yêu thích nào', style: TextStyle(fontSize: 16, color: Colors.grey.shade400)),
      const SizedBox(height: 8),
      Text('Nhấn ··· trên bài viết để thêm vào yêu thích', style: TextStyle(fontSize: 13, color: Colors.grey.shade400), textAlign: TextAlign.center),
    ]),
  );
}

class _ToolbarAction extends StatelessWidget {
  final IconData icon; final String label; final Color color; final bool enabled; final VoidCallback onTap;
  const _ToolbarAction({required this.icon, required this.label, required this.color, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.grey.shade400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 26),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}