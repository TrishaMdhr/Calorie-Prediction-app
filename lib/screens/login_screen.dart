// =============================================================================
// FILE: lib/screens/login_screen.dart
// ROLE: Login screen — email + password authentication
// -----------------------------------------------------------------------------
// - Validates email format and password strength client-side
// - Calls AppProvider.loginAction() → POST /login → stores JWT token
// - Shows loading spinner during server call
// - Offline fallback: checks locally registered users in SharedPreferences
// - On success → navigates to DashboardScreen
// =============================================================================
import 'package:flutter/material.dart';
import 'admin/admin_dashboard_screen.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../providers/app_provider.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _remember = false;
  String? _emailError, _passError;

  bool _validateEmail(String e) {
    if (e.isEmpty) return false;
    if (!e.contains('@')) return false;
    if (!e.contains('.')) return false;
    final parts = e.split('@');
    if (parts.length != 2) return false;
    if (parts[0].isEmpty) return false;
    if (!parts[1].contains('.')) return false;
    final domainParts = parts[1].split('.');
    if (domainParts.last.length < 2) return false;
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e);
  }

  bool _validatePassword(String p) =>
      p.length >= 8 &&
          RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(p);

  void _login() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_validateEmail(email)) {
        _emailError = 'Please enter a valid email (e.g. name@gmail.com)';
      } else {
        _emailError = null;
      }

      if (pass.isEmpty) {
        _passError = 'Please enter your password';
      } else if (!_validatePassword(pass)) {
        _passError = 'Min 8 characters and 1 symbol required';
      } else {
        _passError = null;
      }
    });

    if (_emailError != null || _passError != null) return;

    // Show loading spinner
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final provider = Provider.of<AppProvider>(context, listen: false);
    final error = await provider.loginAction(email, pass);

    if (!mounted) return;
    Navigator.pop(context); // Close spinner

    if (error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ));
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (provider.isAdmin) {
     Navigator.pushReplacement(
     context,
      MaterialPageRoute(
      builder: (_) => const AdminDashboardScreen(),
    ),
  );
} else {
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardScreen(),
    ),
  );
}
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              const Text('Welcome',
                  style: TextStyle(
                      fontSize: 18, color: Colors.black54)),
              const SizedBox(height: 8),
              const CalowrieLogo(fontSize: 32),
              const SizedBox(height: 16),
              const Text('Track your progress',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Log in to track your calories and build\nhealthier eating habits.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text('Login',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Email Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'name@example.com',
                  prefixIcon: const Icon(Icons.email_outlined),
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Password',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscure,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _passError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _remember,
                    onChanged: (v) =>
                        setState(() => _remember = v!),
                    activeColor: AppTheme.primary,
                  ),
                  const Text('Remember me'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen()),
                    ),
                    child: Text('Forgot password?',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Log In',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR LOGIN WITH',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1)),
                ),
                Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const _GoogleIcon(),
                    label: const Text('Google',
                        style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.apple,
                        color: Color(0xFF334155), size: 24),
                    label: const Text('Apple',
                        style: TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("DON'T HAVE AN ACCOUNT? ",
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SignupScreen()),
                    ),
                    child: Text('SIGNUP',
                        style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── caLOWrie Logo ───────────────────────────────────────
class CalowrieLogo extends StatelessWidget {
  final double fontSize;
  const CalowrieLogo({super.key, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF00C853);
    const grey = Color(0xFF334155);

    final greyStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: grey);
    final greenStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: green);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('ca', style: greyStyle),
        Text('L', style: greenStyle),
        Text('O', style: greenStyle),
        Text('W', style: greenStyle),
        Text('rie', style: greyStyle),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300, width: 1),
        color: Colors.white,
      ),
      child: Center(
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'G',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                  fontFamily: 'Arial',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}