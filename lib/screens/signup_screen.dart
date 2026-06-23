import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/user_model.dart';
import '../providers/app_provider.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
  bool _remember = false;
  String? _nameError, _emailError, _passError, _confirmError;

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

  void _signup() {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    setState(() {
      if (name.isEmpty) {
        _nameError = 'Full name is required';
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else {
        _nameError = null;
      }

      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_validateEmail(email)) {
        _emailError = 'Please enter a valid email (e.g. name@gmail.com)';
      } else {
        _emailError = null;
      }

      if (pass.isEmpty) {
        _passError = 'Please enter a password';
      } else if (pass.length < 8) {
        _passError = 'Password must be at least 8 characters';
      } else if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pass)) {
        _passError = 'Must contain at least 1 symbol (e.g. !@#\$)';
      } else {
        _passError = null;
      }

      if (confirm.isEmpty) {
        _confirmError = 'Please confirm your password';
      } else if (pass != confirm) {
        _confirmError = 'Passwords do not match';
      } else {
        _confirmError = null;
      }
    });

    if ([_nameError, _emailError, _passError, _confirmError]
        .every((e) => e == null)) {
      Provider.of<AppProvider>(context, listen: false)
          .registerUser(email, pass, name);

      final user = UserModel(name: name, email: email);
      Provider.of<AppProvider>(context, listen: false).setUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => const DashboardScreen()),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
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
              const Text('Sign Up',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text(
                'Begin your personalized wellness experience',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Full Name',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'e.g. Rajesh Hamal',
                  prefixIcon: const Icon(Icons.person_outline),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 16),
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
                obscureText: _obscure1,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _passError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure1
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure1 = !_obscure1),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Confirm Password',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure2
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscure2 = !_obscure2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Checkbox(
                  value: _remember,
                  onChanged: (v) =>
                      setState(() => _remember = v!),
                  activeColor: AppTheme.primary,
                ),
                const Text('Remember me'),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?',
                      style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Sign Up',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const Row(children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('OR SIGNUP WITH',
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
                  const Text('ALREADY HAVE AN ACCOUNT? ',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                    ),
                    child: Text('LOGIN',
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