import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../home/home_screen.dart';
import '../booking/booking_list_screen.dart';
import '../chat/chat_conversation_screen.dart';
import '../profile/profile_screen.dart';
import '../emergency/emergency_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BookingListScreen(),
    const ChatConversationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home, label: 'Beranda', selected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
                _NavItem(icon: Icons.book_online, label: 'Pesanan', selected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
                _NavItem(icon: Icons.chat, label: 'Chat', selected: _currentIndex == 2, onTap: () => setState(() => _currentIndex = 2)),
                _NavItem(icon: Icons.person, label: 'Profil', selected: _currentIndex == 3, onTap: () => setState(() => _currentIndex = 3)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmergencyScreen())),
        backgroundColor: AppTheme.error,
        child: const Icon(Icons.sos, color: Colors.white),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? AppTheme.primary : AppTheme.textSecondary, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? AppTheme.primary : AppTheme.textSecondary,
          )),
        ],
      ),
    );
  }
}
