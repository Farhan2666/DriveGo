import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';
import '../home/main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String _role = 'customer';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Buat Akun Baru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  prefixIcon: Icon(Icons.phone_android),
                ),
                validator: (v) => v == null || v.length < 10 ? 'Nomor telepon tidak valid' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (opsional)',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 16),

              const Text('Daftar sebagai:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _RoleChip(
                      label: 'Customer',
                      icon: Icons.person,
                      selected: _role == 'customer',
                      onTap: () => setState(() => _role = 'customer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleChip(
                      label: 'Driver',
                      icon: Icons.directions_car,
                      selected: _role == 'driver',
                      onTap: () => setState(() => _role = 'driver'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await _authService.register(
        fullname: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      SocketService().connect(res['data']['token']);
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (_) => const MainScreen(),
        ), (route) => false);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendaftar. Coba lagi.'),
            backgroundColor: AppTheme.error),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.primary : AppTheme.border, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}
