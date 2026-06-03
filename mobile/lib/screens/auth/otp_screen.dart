import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../home/main_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _authService = AuthService();
  String _otp = '';
  bool _isLoading = false;
  int _resendTimer = 60;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendTimer > 0) _resendTimer--;
      });
      return _resendTimer > 0;
    });
  }

  Future<void> _verifyOtp() async {
    if (_otp.length < 6) return;
    setState(() => _isLoading = true);

    try {
      final res = await _authService.loginWithOtp(widget.phone, _otp);
      SocketService().connect(res['data']['token']);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ), (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP salah'), backgroundColor: AppTheme.error),
      );
    }
    setState(() => _isLoading = false);
  }

  Future<void> _resendOtp() async {
    try {
      await _authService.sendOtp(widget.phone);
      setState(() {
        _resendTimer = 60;
        _startResendTimer();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP telah dikirim ulang')),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.sms_otp, size: 64, color: AppTheme.primary),
            const SizedBox(height: 16),
            Text('Masukkan Kode OTP',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Kode telah dikirim ke ${widget.phone}',
              style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),

            PinField(
              onChanged: (v) => _otp = v,
              onCompleted: (_) => _verifyOtp(),
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _otp.length < 6 ? null : _verifyOtp,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verifikasi'),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: _resendTimer > 0 ? null : _resendOtp,
              child: Text(_resendTimer > 0
                  ? 'Kirim ulang dalam $_resendTimer detik'
                  : 'Kirim ulang OTP'),
            ),
          ],
        ),
      ),
    );
  }
}

class PinField extends StatelessWidget {
  final void Function(String) onChanged;
  final void Function(String) onCompleted;

  const PinField({super.key, required this.onChanged, required this.onCompleted});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 48,
          child: TextField(
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
            ),
            onChanged: (v) {
              onChanged(v);
              if (v.isNotEmpty && i < 5) {
                FocusScope.of(context).nextFocus();
              }
              if (i == 5 && v.isNotEmpty) {
                onCompleted(v);
              }
            },
          ),
        );
      }),
    );
  }
}
