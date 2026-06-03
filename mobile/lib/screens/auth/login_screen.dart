import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import 'otp_screen.dart';
import 'register_screen.dart';
import '../home/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _usePassword = false;

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showError('Masukkan nomor telepon yang valid');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.sendOtp(phone);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => OtpScreen(phone: phone),
        ));
      }
    } catch (e) {
      _showError('Gagal mengirim OTP');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loginPassword() async {
    setState(() => _isLoading = true);
    try {
      final res = await _authService.loginPassword(
        _phoneController.text.trim(),
        _passwordController.text,
      );
      SocketService().connect(res['data']['token']);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ));
      }
    } catch (e) {
      _showError('Nomor atau password salah');
    }
    setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Icon(Icons.directions_car, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text('DriveGo', style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold, color: AppTheme.primary)),
              const SizedBox(height: 8),
              Text('Pesan Supir dan Mobil Travel dengan Mudah',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
              const SizedBox(height: 48),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone_android),
                  hintText: '08xxxxxxxxxx',
                ),
              ),
              const SizedBox(height: 16),

              if (_usePassword) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loginPassword,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Masuk'),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendOtp,
                    child: _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Kirim OTP'),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              TextButton(
                onPressed: () => setState(() => _usePassword = !_usePassword),
                child: Text(_usePassword ? 'Gunakan OTP' : 'Gunakan Password'),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  const Expanded(child: Divider()),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('atau', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const RegisterScreen(),
                )),
                icon: const Icon(Icons.person_add),
                label: const Text('Daftar Akun Baru'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
