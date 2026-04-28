import 'package:flutter/material.dart';
import '../services/auth_service.dart';
// Màn hình quên mật khẩu
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnack('Vui lòng nhập email của bạn!');
      return;
    }

    setState(() => _isLoading = true);

    // Tìm mật khẩu trong Hive theo email
    final result = await AuthService.getPasswordByEmail(email);

    setState(() => _isLoading = false);

    if (result == null) {
      _showSnack('Email này chưa được đăng ký!');
      return;
    }

    // Hiện dialog với mật khẩu
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PasswordDialog(
          email: email,
          password: result,
          onClose: () {
            Navigator.pop(context); // đóng dialog
            Navigator.pop(context); // về login
          },
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB5835A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
            child: Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: isDark ? Colors.white : const Color(0xFF2C1810),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Icon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5835A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 36,
                    color: Color(0xFFB5835A),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Tiêu đề
              Center(
                child: Text(
                  'Quên mật khẩu?',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2C1810),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Nhập email đã đăng ký, chúng tôi sẽ\ncho bạn xem lại mật khẩu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Label email
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),

              // TextField email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF2C1810),
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập email của bạn',
                  hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFFB5835A),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
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
                    borderSide: const BorderSide(
                        color: Color(0xFFB5835A), width: 1.5),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Nút tìm mật khẩu
              GestureDetector(
                onTap: _isLoading ? null : _sendReset,
                child: Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFB5835A).withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text(
                      'Tìm mật khẩu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quay lại đăng nhập
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Nhớ mật khẩu rồi? ',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14),
                      children: const [
                        TextSpan(
                          text: 'Đăng nhập',
                          style: TextStyle(
                            color: Color(0xFFB5835A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dialog hiện mật khẩu ─────────────────────────────────────────────────────

class _PasswordDialog extends StatefulWidget {
  final String email;
  final String password;
  final VoidCallback onClose;

  const _PasswordDialog({
    required this.email,
    required this.password,
    required this.onClose,
  });

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor:
      isDark ? const Color(0xFF2A2420) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFB5835A).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open_rounded,
                color: Color(0xFFB5835A),
                size: 28,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Mật khẩu của bạn',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF2C1810),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.email,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB5835A),
              ),
            ),

            const SizedBox(height: 20),

            // Ô hiện mật khẩu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFB5835A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showPassword ? widget.password : '••••••••',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: _showPassword ? 1 : 4,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF2C1810),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFFB5835A),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Hãy ghi nhớ và bảo mật mật khẩu của bạn.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),

            const SizedBox(height: 20),

            // Nút đóng & về đăng nhập
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB5835A), Color(0xFF8B5E3C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Về trang đăng nhập',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}