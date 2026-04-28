import 'package:hive/hive.dart';

part 'diary_entry.g.dart';

@HiveType(typeId: 0)
class DiaryEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;      // ✅ bỏ final

  @HiveField(2)
  String content;    // ✅ bỏ final

  @HiveField(3)
  String mood;       // ✅ bỏ final

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  String? imagePath;

  @HiveField(7)
  String? videoPath;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.mood,
    required this.date,
    this.isFavorite = false,
    this.imagePath,
    this.videoPath,
  });
}