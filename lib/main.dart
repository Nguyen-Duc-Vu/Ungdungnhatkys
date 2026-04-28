import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ Thêm dòng này

import 'services/hive_service.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Hive + đăng ký adapter
  await HiveService.init();

  // 2. Mở tất cả box dùng chung — PHẢI mở trước khi dùng
  await Hive.openBox('users');
  await Hive.openBox('session');
  await Hive.openBox('settings'); // ✅ Fix: mở settings box cho ProfileScreen

  // 3. Nếu đã đăng nhập → mở box nhật ký của user đó luôn
  if (AuthService.isLoggedIn) {
    await HiveService.switchUser();
  }

  // 4. Thông báo
  if (!kIsWeb) {
    await NotificationService.init();
  }

  // 5. Theme
  final themeProvider = ThemeProvider();
  await themeProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final startRoute = AuthService.isLoggedIn
        ? AppRoutes.home
        : AppRoutes.login;

    return MaterialApp(
      title: 'Nhật Ký',
      debugShowCheckedModeBanner: false,

      // ✅ Thêm 3 dòng này để DatePickerDialog hoạt động
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      locale: const Locale('vi', 'VN'),

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5835A),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB5835A),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeProvider.themeMode,
      initialRoute: startRoute,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}