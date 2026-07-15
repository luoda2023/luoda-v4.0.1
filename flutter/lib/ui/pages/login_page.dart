// flutter/lib/ui/pages/login_page.dart
// 登录/注册页面（微信风格）

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/app_theme.dart';
import '../components/avatar.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _pwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    // 跳转主页
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Icon(Icons.desktop_windows, size: 48, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('LUODA 远程控制', style: AppTextStyles.headline1),
                  const SizedBox(height: 8),
                  Text('安全 · 高效 · 跨平台', style: AppTextStyles.bodyText2),
                  const SizedBox(height: 40),
                  // 邮箱/账号
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: '邮箱/手机号',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v != null && v.contains('@') ? null : '请输入有效邮箱',
                  ),
                  const SizedBox(height: 16),
                  // 密码
                  TextFormField(
                    controller: _pwdCtrl,
                    obscureText: _obscurePwd,
                    decoration: InputDecoration(
                      labelText: '密码',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePwd ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v != null && v.length >= 6 ? null : '密码至少6位',
                  ),
                  const SizedBox(height: 12),
                  // 记住我 + 忘记密码
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: AppColors.primaryGreen,
                      ),
                      const Text('记住我'),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Get.toNamed('/forgot-password'),
                        child: const Text('忘记密码?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // 登录按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('登录', style: AppTextStyles.button),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 分割线
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('或使用其他方式', style: AppTextStyles.caption),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // 社交登录
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SocialButton(icon: Icons.g_mobiledata, label: 'Google', onTap: () {}),
                      const SizedBox(width: 16),
                      _SocialButton(icon: Icons.apple, label: 'Apple', onTap: () {}),
                      const SizedBox(width: 16),
                      _SocialButton(icon: Icons.wechat, label: '微信', onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // 注册
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('没有账号?', style: AppTextStyles.bodyText2),
                      TextButton(
                        onPressed: () => Get.toNamed('/register'),
                        child: Text('立即注册', style: AppTextStyles.button.copyWith(color: AppColors.primaryGreen)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyText2),
          ],
        ),
      ),
    );
  }
}