import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/hive_service.dart';   // ✅ thêm import
import 'login_screen.dart';
import 'home_screen.dart';
//Màn hình đăng ký tài khoản
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty ||
        password.isEmpty || confirm.isEmpty) {
      _showSnack('Vui lòng nhập đầy đủ thông tin!');
      return;
    }
    if (password != confirm) {
      _showSnack('Mật khẩu xác nhận không khớp!');
      return;
    }
    if (password.length < 6) {
      _showSnack('Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }
    if (!_agreeTerms) {
      _showSnack('Vui lòng đồng ý với điều khoản sử dụng!');
      return;
    }

    setState(() => _isLoading = true);

    final error = await AuthService.register(
      name: name,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (error != null) {
      _showSnack(error);
      return;
    }

    // ✅ Mở đúng box nhật ký của user vừa đăng ký
    await HiveService.switchUser();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
            borderRadius: BorderRadius.circular(12)),
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

              // Tiêu đề
              Text(
                'Tạo tài khoản',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2C1810),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bắt đầu hành trình viết nhật ký ✨',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),

              const SizedBox(height: 36),

              // Họ tên
              _buildLabel('Họ và tên', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'Nhập họ và tên',
                icon: Icons.person_outline_rounded,
                isDark: isDark,
              ),

              const SizedBox(height: 20),

              // Email
              _buildLabel('Email', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'Nhập email của bạn',
                icon: Icons.email_outlined,
                isDark: isDark,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              // Mật khẩu
              _buildLabel('Mật khẩu', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'Tối thiểu 6 ký tự',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 20),

              // Xác nhận mật khẩu
              _buildLabel('Xác nhận mật khẩu', isDark),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _confirmController,
                hint: 'Nhập lại mật khẩu',
                icon: Icons.lock_outline_rounded,
                isDark: isDark,
                obscure: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm),
                ),
              ),

              const SizedBox(height: 20),

              // Checkbox điều khoản
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreeTerms = !_agreeTerms),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _agreeTerms
                            ? const Color(0xFFB5835A)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _agreeTerms
                              ? const Color(0xFFB5835A)
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: _agreeTerms
                          ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _agreeTerms = !_agreeTerms),
                      child: RichText(
                        text: TextSpan(
                          text: 'Tôi đồng ý với ',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                            height: 1.5,
                          ),
                          children: const [
                            TextSpan(
                              text: 'Điều khoản sử dụng',
                              style: TextStyle(
                                color: Color(0xFFB5835A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: ' và '),
                            TextSpan(
                              text: 'Chính sách bảo mật',
                              style: TextStyle(
                                color: Color(0xFFB5835A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Nút đăng ký
              GestureDetector(
                onTap: _isLoading ? null : _register,
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
                        color: const Color(0xFFB5835A)
                            .withValues(alpha: 0.35),
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
                      'Tạo tài khoản',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Chuyển sang đăng nhập
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                  ),
                  child: RichText(
                    text: TextSpan(
                      text: 'Đã có tài khoản? ',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
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

              const SizedBox(height: 32),
            ],
          ),
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
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.grey.shade600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.white : const Color(0xFF2C1810),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
        TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon:
        Icon(icon, color: const Color(0xFFB5835A), size: 20),
        suffixIcon: suffixIcon,
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
    );
  }
}