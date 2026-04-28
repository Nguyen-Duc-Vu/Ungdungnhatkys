import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/hive_service.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<DiaryEntry> _filtered = [];
  final _controller = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search(String raw) {
    final keyword = raw.trim();
    // ✅ dùng getAllEntries() sync
    final all = HiveService.getAllEntries();

    setState(() {
      _hasSearched = keyword.isNotEmpty;
      if (!_hasSearched) { _filtered = []; return; }
      _filtered = all.where((e) => _matches(e, keyword)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    });
  }

  bool _matches(DiaryEntry e, String keyword) {
    final k = keyword.toLowerCase();
    final d = e.date;

    if (e.title.toLowerCase().contains(k)) return true;
    if (e.content.toLowerCase().contains(k)) return true;

    final slashParts = keyword.split('/');
    if (slashParts.length == 2) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      if (day != null && month != null) return d.day == day && d.month == month;
    }
    if (slashParts.length == 3) {
      final day = int.tryParse(slashParts[0]);
      final month = int.tryParse(slashParts[1]);
      final year = int.tryParse(slashParts[2]);
      if (day != null && month != null && year != null)
        return d.day == day && d.month == month && d.year == year;
    }

    final num = int.tryParse(keyword);
    if (num != null) {
      if (num >= 1 && num <= 31 && d.day == num) return true;
      if (num >= 1 && num <= 12 && d.month == num) return true;
      if (num > 1000 && d.year == num) return true;
    }

    const monthNames = [
      'tháng 1','tháng 2','tháng 3','tháng 4',
      'tháng 5','tháng 6','tháng 7','tháng 8',
      'tháng 9','tháng 10','tháng 11','tháng 12',
    ];
    const monthNamesWord = [
      'tháng giêng','tháng hai','tháng ba','tháng tư',
      'tháng năm','tháng sáu','tháng bảy','tháng tám',
      'tháng chín','tháng mười','tháng mười một','tháng mười hai',
    ];
    for (int i = 0; i < 12; i++) {
      if (k == monthNames[i] || k == monthNamesWord[i]) return d.month == i + 1;
    }

    const weekdays = [
      'thứ hai','thứ ba','thứ tư','thứ năm',
      'thứ sáu','thứ bảy','chủ nhật',
    ];
    for (int i = 0; i < weekdays.length; i++) {
      if (k == weekdays[i]) return d.weekday == i + 1;
    }

    return false;
  }

  String _formatDate(DateTime d) {
    const weekdays = ['Thứ Hai','Thứ Ba','Thứ Tư','Thứ Năm','Thứ Sáu','Thứ Bảy','Chủ Nhật'];
    return '${weekdays[d.weekday - 1]}, ${d.day}/${d.month}/${d.year}';
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
        title: Text('Tìm kiếm', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF2C1810))),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Tiêu đề, nội dung, ngày, tháng...',
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFB5835A)),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () { _controller.clear(); _search(''); })
                    : null,
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEDE5D8))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFB5835A), width: 1.5)),
              ),
            ),
          ),
          if (_hasSearched && _filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('${_filtered.length} bài viết', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              ),
            ),
          Expanded(
            child: !_hasSearched
                ? _buildIdleState()
                : _filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _SearchCard(entry: _filtered[i], formatDate: _formatDate, isDark: isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('Tìm theo tiêu đề, nội dung\nhoặc gõ "17/4", "tháng 4"...', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
    ]),
  );

  Widget _buildEmptyState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
      const SizedBox(height: 12),
      Text('Không tìm thấy kết quả', style: TextStyle(fontSize: 15, color: Colors.grey.shade400)),
    ]),
  );
}

class _SearchCard extends StatelessWidget {
  final DiaryEntry entry;
  final String Function(DateTime) formatDate;
  final bool isDark;
  const _SearchCard({required this.entry, required this.formatDate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(entry: entry))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2420) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEDE5D8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.imagePath != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.asset(entry.imagePath!, height: 140, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.mood, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF2C1810)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(formatDate(entry.date), style: TextStyle(fontSize: 11, color: const Color(0xFFB5835A).withValues(alpha: 0.8))),
                        if (entry.content.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(entry.content, style: TextStyle(fontSize: 12, color: Colors.grey.shade500), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}