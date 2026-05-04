import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../models/diary_entry.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'favorite_screen.dart';
import '../services/hive_service.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  List<DiaryEntry> _entries = [];

  @override
  void initState() { super.initState(); _loadEntries(); }

  void _loadEntries() => setState(() => _entries = HiveService.getAllEntries());

  // ✅ FIX 1: getter _favorites — luôn sync với _entries
  List<DiaryEntry> get _favorites => _entries.where((e) => e.isFavorite).toList();

  void _addEntry(DiaryEntry e) async { await HiveService.addEntry(e); _loadEntries(); }
  void _deleteEntry(String id) async { await HiveService.deleteEntry(id); _loadEntries(); }
  void _deleteMultiple(List<String> ids) async {
    for (final id in ids) await HiveService.deleteEntry(id);
    _loadEntries();
  }
  void _toggleFavorite(String id) async {
    final e = _entries.firstWhere((e) => e.id == id);
    e.isFavorite = !e.isFavorite;
    await HiveService.updateEntry(e);
    _loadEntries();
  }
  void _toggleFavoriteMultiple(List<String> ids) async {
    for (final id in ids) {
      final e = _entries.firstWhere((e) => e.id == id);
      e.isFavorite = !e.isFavorite;
      await HiveService.updateEntry(e);
    }
    _loadEntries();
  }
  void _openDetail(DiaryEntry e) async {
    final result = await Navigator.pushNamed<dynamic>(context, AppRoutes.detail, arguments: e);
    if (result == 'deleted' || result == 'updated') _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF7F2),
      body: IndexedStack(
        index: _currentTab,
        children: [
          _HomeTab(
            entries: _entries,
            onDelete: _deleteEntry,
            onDeleteMultiple: _deleteMultiple,
            onToggleFavorite: _toggleFavorite,
            onToggleFavoriteMultiple: _toggleFavoriteMultiple,
            onOpenDetail: _openDetail,
          ),
          const SearchScreen(),
          const SizedBox(),
          // ✅ FIX 2: truyền favorites và callback vào FavoriteScreen
          FavoriteScreen(
            favorites: _favorites,
            onDataChanged: _loadEntries,
          ),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentTab,
        onTap: (i) async {
          if (i == 2) {
            final entry = await Navigator.pushNamed<DiaryEntry?>(context, AppRoutes.write);
            if (entry != null) _addEntry(entry);
            return;
          }
          setState(() => _currentTab = i);
        },
      ),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFFB5835A);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242424) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, accent: accent, onTap: onTap),
              _NavItem(icon: Icons.search_rounded, label: 'Tìm kiếm', index: 1, current: currentIndex, accent: accent, onTap: onTap),
              Expanded(
                child: GestureDetector(
                  onTap: () => onTap(2),
                  child: Center(
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFFB5835A).withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              _NavItem(icon: Icons.favorite_rounded, label: 'Yêu thích', index: 3, current: currentIndex, accent: accent, onTap: onTap),
              _NavItem(icon: Icons.person_rounded, label: 'Cá nhân', index: 4, current: currentIndex, accent: accent, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon; final String label; final int index, current; final Color accent; final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.accent, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isActive = current == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? accent : Colors.grey.shade400, size: 24),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: isActive ? accent : Colors.grey.shade400, fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatefulWidget {
  final List<DiaryEntry> entries;
  final ValueChanged<String> onDelete;
  final Function(List<String>) onDeleteMultiple;
  final ValueChanged<String> onToggleFavorite;
  final Function(List<String>) onToggleFavoriteMultiple;
  final Function(DiaryEntry) onOpenDetail;

  const _HomeTab({
    required this.entries, required this.onDelete, required this.onDeleteMultiple,
    required this.onToggleFavorite, required this.onToggleFavoriteMultiple, required this.onOpenDetail,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isSelecting = false;
  final Set<String> _selected = {};

  void _enterSelectMode() => setState(() { _isSelecting = true; _selected.clear(); });
  void _exitSelectMode() => setState(() { _isSelecting = false; _selected.clear(); });

  void _toggleSelect(String id) => setState(() {
    _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
  });

  void _selectAll() => setState(() => _selected.addAll(widget.entries.map((e) => e.id)));

  void _confirmDeleteSelected() {
    if (_selected.isEmpty) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá ${_selected.length} bài viết?', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
        content: Text('Hành động này không thể hoàn tác.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); widget.onDeleteMultiple(_selected.toList()); _exitSelectMode(); },
            child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAll() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2A2420) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Xoá tất cả ${widget.entries.length} bài viết?', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
        content: Text('Toàn bộ nhật ký sẽ bị xoá vĩnh viễn.', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Huỷ', style: TextStyle(color: Colors.grey.shade500))),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDeleteMultiple(widget.entries.map((e) => e.id).toList());
              _exitSelectMode();
            },
            child: const Text('Xoá tất cả', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  List<_MemoryItem> _getMemories() {
    final now = DateTime.now();
    final memories = <_MemoryItem>[];
    for (final e in widget.entries) {
      final diff = now.year - e.date.year;
      if (diff >= 1 && e.date.month == now.month && e.date.day == now.day)
        memories.add(_MemoryItem(entry: e, label: '$diff năm trước'));
      else if (diff == 0 && now.month - e.date.month == 1 && e.date.day == now.day)
        memories.add(_MemoryItem(entry: e, label: '1 tháng trước'));
    }
    return memories;
  }

  List<Widget> _buildGroupedList(bool isDark) {
    final widgets = <Widget>[];
    final now = DateTime.now();
    String? lastKey;
    for (final e in widget.entries) {
      final d = e.date;
      String key;
      if (d.year == now.year && d.month == now.month && d.day == now.day) key = 'Hôm nay';
      else if (d.year == now.year && d.month == now.month && now.day - d.day == 1) key = 'Hôm qua';
      else {
        const wd = ['Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ Nhật'];
        key = '${wd[d.weekday - 1]}, ${d.day} thg ${d.month}';
      }
      if (key != lastKey) { widgets.add(_DateHeader(label: key, isDark: isDark)); lastKey = key; }

      final isSelected = _selected.contains(e.id);
      if (e.videoPath != null && e.videoPath!.isNotEmpty) {
        widgets.add(_VideoCard(
          entry: e, isDark: isDark,
          isSelecting: _isSelecting, isSelected: isSelected,
          onTap: () => _isSelecting ? _toggleSelect(e.id) : widget.onOpenDetail(e),
          onLongPress: () { if (!_isSelecting) _enterSelectMode(); _toggleSelect(e.id); },
          onDelete: widget.onDelete, onToggleFavorite: widget.onToggleFavorite,
        ));
      } else {
        widgets.add(_EntryCard(
          entry: e, isDark: isDark,
          isSelecting: _isSelecting, isSelected: isSelected,
          onTap: () => _isSelecting ? _toggleSelect(e.id) : widget.onOpenDetail(e),
          onLongPress: () { if (!_isSelecting) _enterSelectMode(); _toggleSelect(e.id); },
          onDelete: widget.onDelete, onToggleFavorite: widget.onToggleFavorite,
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Chào buổi sáng ☀️' : now.hour < 18 ? 'Chào buổi chiều 🌤️' : 'Chào buổi tối 🌙';
    final memories = _getMemories();
    final listWidgets = _buildGroupedList(isDark);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark ? [const Color(0xFF2C2016), const Color(0xFF1A1A1A)] : [const Color(0xFFF5EDE0), const Color(0xFFFAF7F2)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSelecting ? '${_selected.length} đã chọn' : greeting,
                            style: const TextStyle(fontSize: 14, color: Color(0xFFB5835A), fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (_isSelecting)
                          TextButton(
                            onPressed: _exitSelectMode,
                            child: const Text('Xong', style: TextStyle(color: Color(0xFFB5835A), fontWeight: FontWeight.w700)),
                          )
                        else
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white70 : const Color(0xFF2C1810)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            onSelected: (val) {
                              if (val == 'select') _enterSelectMode();
                              if (val == 'delete_all') _confirmDeleteAll();
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'select', child: Row(children: [
                                Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFFB5835A)),
                                SizedBox(width: 10), Text('Chọn bài viết'),
                              ])),
                              const PopupMenuItem(value: 'delete_all', child: Row(children: [
                                Icon(Icons.delete_sweep_rounded, size: 20, color: Colors.red),
                                SizedBox(width: 10), Text('Xoá tất cả', style: TextStyle(color: Colors.red)),
                              ])),
                            ],
                          ),
                      ],
                    ),
                    Text(
                      _isSelecting ? 'Chọn bài viết' : 'Nhật ký',
                      style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF2C1810), letterSpacing: -0.5),
                    ),
                    if (_isSelecting) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _selectAll,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.select_all_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                            const SizedBox(width: 6),
                            Text('Chọn tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54)),
                          ]),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 14),
                      Row(children: [
                        _StatChip(icon: Icons.book_rounded, label: '${widget.entries.length} bài viết', isDark: isDark),
                        const SizedBox(width: 10),
                        _StatChip(icon: Icons.favorite_rounded, label: '${widget.entries.where((e) => e.isFavorite).length} yêu thích', isDark: isDark),
                      ]),
                    ],
                  ],
                ),
              ),
            ),

            if (memories.isNotEmpty && !_isSelecting)
              SliverToBoxAdapter(child: _OnThisDayBanner(memories: memories, isDark: isDark, onTap: widget.onOpenDetail)),

            if (widget.entries.isEmpty)
              SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(delegate: SliverChildBuilderDelegate((ctx, i) => listWidgets[i], childCount: listWidgets.length)),
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
                  _ToolbarAction(
                    icon: Icons.favorite_border_rounded, label: 'Yêu thích',
                    color: const Color(0xFFE57373), enabled: _selected.isNotEmpty,
                    onTap: () { widget.onToggleFavoriteMultiple(_selected.toList()); _exitSelectMode(); },
                  ),
                  Container(width: 1, height: 36, color: isDark ? Colors.white12 : Colors.black12),
                  _ToolbarAction(
                    icon: Icons.delete_outline_rounded, label: 'Xoá',
                    color: Colors.red, enabled: _selected.isNotEmpty,
                    onTap: _confirmDeleteSelected,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Toolbar Action ────────────────────────────────────────────────────────────

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

// ── Date Header ───────────────────────────────────────────────────────────────

class _DateHeader extends StatelessWidget {
  final String label; final bool isDark;
  const _DateHeader({required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
  );
}

// ── Entry Card ────────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final DiaryEntry entry; final bool isDark, isSelecting, isSelected;
  final VoidCallback onTap, onLongPress;
  final ValueChanged<String> onDelete, onToggleFavorite;

  const _EntryCard({
    required this.entry, required this.isDark, required this.isSelecting, required this.isSelected,
    required this.onTap, required this.onLongPress, required this.onDelete, required this.onToggleFavorite,
  });

  String _formatDate(DateTime d) {
    const m = ['Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'];
    return '${d.day} ${m[d.month - 1]}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFB5835A).withValues(alpha: isDark ? 0.22 : 0.10) : isDark ? const Color(0xFF2A2420) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFFB5835A) : isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDE5D8), width: isSelected ? 1.5 : 1),
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFFB5835A).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            if (isSelecting) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24, height: 24,
                decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? const Color(0xFFB5835A) : Colors.transparent, border: Border.all(color: isSelected ? const Color(0xFFB5835A) : Colors.grey.shade400, width: 1.5)),
                child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 14) : null,
              ),
              const SizedBox(width: 12),
            ],
            Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFB5835A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Center(child: Text(entry.mood, style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(entry.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF2C1810)), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (entry.isFavorite && !isSelecting) const Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFE57373)),
              ]),
              const SizedBox(height: 4),
              Text(_formatDate(entry.date), style: TextStyle(fontSize: 11, color: const Color(0xFFB5835A).withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
              if (entry.content.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500)),
              ],
            ])),
            if (!isSelecting)
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (val) { if (val == 'delete') onDelete(entry.id); if (val == 'favorite') onToggleFavorite(entry.id); },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'favorite', child: Row(children: [Icon(entry.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFE57373), size: 18), const SizedBox(width: 10), Text(entry.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích')])),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: Colors.red))])),
                ],
              ),
          ]),
        ),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────

class _VideoCard extends StatefulWidget {
  final DiaryEntry entry; final bool isDark, isSelecting, isSelected;
  final VoidCallback onTap, onLongPress;
  final ValueChanged<String> onDelete, onToggleFavorite;

  const _VideoCard({
    required this.entry, required this.isDark, required this.isSelecting, required this.isSelected,
    required this.onTap, required this.onLongPress, required this.onDelete, required this.onToggleFavorite,
  });

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  Uint8List? _thumbnail;
  bool _loadingThumb = true;
  String? _currentVideoPath;

  @override
  void initState() {
    super.initState();
    _currentVideoPath = widget.entry.videoPath;
    _generateThumbnail();
  }

  @override
  void didUpdateWidget(_VideoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entry.videoPath != _currentVideoPath) {
      _currentVideoPath = widget.entry.videoPath;
      setState(() { _thumbnail = null; _loadingThumb = true; });
      _generateThumbnail();
    }
  }

  Future<void> _generateThumbnail() async {
    if (widget.entry.videoPath == null) return;
    try {
      final thumb = await VideoThumbnail.thumbnailData(video: widget.entry.videoPath!, imageFormat: ImageFormat.JPEG, maxWidth: 800, quality: 85);
      if (mounted) setState(() { _thumbnail = thumb; _loadingThumb = false; });
    } catch (_) { if (mounted) setState(() => _loadingThumb = false); }
  }

  String _fmt(DateTime d) {
    const wd = ['Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ Nhật'];
    const m = ['Th1','Th2','Th3','Th4','Th5','Th6','Th7','Th8','Th9','Th10','Th11','Th12'];
    return '${wd[d.weekday-1]}, ${d.day} ${m[d.month-1]}';
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return GestureDetector(
      onTap: widget.onTap, onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), color: Colors.grey.shade900,
          border: widget.isSelected ? Border.all(color: const Color(0xFFB5835A), width: 2.5) : null,
        ),
        child: Stack(children: [
          _loadingThumb
              ? Container(height: 220, color: Colors.grey.shade900, child: const Center(child: CircularProgressIndicator(color: Color(0xFFB5835A), strokeWidth: 2)))
              : _thumbnail != null
              ? Image.memory(_thumbnail!, height: 220, width: double.infinity, fit: BoxFit.cover)
              : Container(height: 220, color: Colors.grey.shade900, child: const Icon(Icons.videocam_off_rounded, color: Colors.white38, size: 48)),
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15), Colors.black.withValues(alpha: 0.72)],
            stops: const [0.45, 0.65, 1.0],
          )))),
          if (widget.isSelecting)
            Positioned(top: 12, left: 12, child: AnimatedContainer(
              duration: const Duration(milliseconds: 150), width: 28, height: 28,
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.isSelected ? const Color(0xFFB5835A) : Colors.black.withValues(alpha: 0.45), border: Border.all(color: widget.isSelected ? const Color(0xFFB5835A) : Colors.white.withValues(alpha: 0.7), width: 1.5)),
              child: widget.isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
            )),
          if (!widget.isSelecting)
            Positioned(top: 0, bottom: 44, left: 0, right: 0, child: Center(child: Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42), shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.5)),
              child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ))),
          Positioned(bottom: 0, left: 0, right: 0, child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 8, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                if (e.title.isNotEmpty) Text(e.title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(_fmt(e.date), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ])),
              if (!widget.isSelecting)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.white.withValues(alpha: 0.85), size: 22),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (val) { if (val == 'delete') widget.onDelete(e.id); if (val == 'favorite') widget.onToggleFavorite(e.id); },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'favorite', child: Row(children: [Icon(e.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: const Color(0xFFE57373), size: 18), const SizedBox(width: 10), Text(e.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích')])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, color: Colors.red, size: 18), SizedBox(width: 10), Text('Xóa', style: TextStyle(color: Colors.red))])),
                  ],
                ),
            ]),
          )),
          if (e.isFavorite && !widget.isSelecting)
            Positioned(top: 12, left: 12, child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_rounded, color: Color(0xFFE57373), size: 14),
            )),
        ]),
      ),
    );
  }
}

// ── Memory Item / Banner ──────────────────────────────────────────────────────

class _MemoryItem { final DiaryEntry entry; final String label; const _MemoryItem({required this.entry, required this.label}); }

class _OnThisDayBanner extends StatelessWidget {
  final List<_MemoryItem> memories; final bool isDark; final Function(DiaryEntry) onTap;
  const _OnThisDayBanner({required this.memories, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2016) : const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFB5835A).withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8), child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: const Color(0xFFB5835A).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)), child: const Center(child: Text('🕰️', style: TextStyle(fontSize: 16)))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ký ức hôm nay', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFB5835A))),
            Text('Ngày này trong quá khứ...', style: TextStyle(fontSize: 11, color: const Color(0xFFB5835A).withValues(alpha: 0.7))),
          ]),
        ])),
        SizedBox(height: 90, child: ListView.builder(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
          itemCount: memories.length,
          itemBuilder: (_, i) {
            final m = memories[i];
            return GestureDetector(onTap: () => onTap(m.entry), child: Container(
              width: 200, margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF3A2C1E) : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFB5835A).withValues(alpha: 0.2))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Text(m.entry.mood, style: const TextStyle(fontSize: 14)), const SizedBox(width: 6), Expanded(child: Text(m.entry.title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810)), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                const SizedBox(height: 4),
                Text(m.entry.content, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                const Spacer(),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFB5835A).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)), child: Text(m.label, style: const TextStyle(fontSize: 10, color: Color(0xFFB5835A), fontWeight: FontWeight.w600))),
              ]),
            ));
          },
        )),
      ]),
    );
  }
}

// ── Stat Chip / Empty State ───────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon; final String label; final bool isDark;
  const _StatChip({required this.icon, required this.label, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFB5835A).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: const Color(0xFFB5835A)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFFB5835A), fontWeight: FontWeight.w600)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 100, height: 100, decoration: BoxDecoration(color: const Color(0xFFB5835A).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_stories_rounded, size: 48, color: Color(0xFFB5835A))),
      const SizedBox(height: 20),
      const Text('Chưa có nhật ký nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFB5835A))),
      const SizedBox(height: 8),
      Text('Nhấn ✏️ để bắt đầu viết\nnhật ký đầu tiên của bạn', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.6)),
    ]),
  );
}
##################  #####
