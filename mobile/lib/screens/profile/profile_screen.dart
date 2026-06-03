import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/socket_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _authService.getProfile();
      setState(() {
        _user = res['data'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SocketService().disconnect();
      await _authService.logout();
      if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
        builder: (_) => const Scaffold(), // Will rebuild with auth gate
      ), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(_user?['fullname'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(_user?['phone'] ?? '',
                    style: const TextStyle(color: AppTheme.textSecondary)),
                  if (_user?['email'] != null)
                    Text(_user!['email'], style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_user?['role'] ?? '').toString().toUpperCase(),
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _MenuItem(
                    icon: Icons.person,
                    label: 'Edit Profil',
                    onTap: () => _showEditProfile(),
                  ),
                  _MenuItem(
                    icon: Icons.notifications,
                    label: 'Notifikasi',
                    trailing: 'Aktif',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.security,
                    label: 'Keamanan',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.help,
                    label: 'Bantuan',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.info,
                    label: 'Tentang',
                    subtitle: 'v1.0.0',
                    onTap: () {},
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showEditProfile() {
    final nameController = TextEditingController(text: _user?['fullname'] ?? '');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Lengkap'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _authService.updateProfile({'fullname': nameController.text});
                _loadProfile();
                Navigator.pop(context);
              } catch (_) {}
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon, required this.label, this.subtitle, this.trailing, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(label),
        subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
        trailing: trailing != null
            ? Text(trailing!, style: const TextStyle(color: AppTheme.textSecondary))
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
