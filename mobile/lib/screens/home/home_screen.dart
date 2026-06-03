import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/driver_service.dart';
import '../../services/booking_service.dart';
import '../booking/create_booking_screen.dart';
import '../driver/driver_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _driverService = DriverService();
  final _searchController = TextEditingController();
  List _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final res = await _driverService.getDrivers(params: {'per_page': 10});
      _drivers = res['data']['data'] ?? [];
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _search() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => CreateBookingScreen(searchQuery: _searchController.text),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DriveGo'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDrivers,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari driver atau tujuan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(icon: const Icon(Icons.arrow_forward), onPressed: _search)
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    filled: false,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(height: 20),

              // Quick actions
              Row(
                children: [
                  _QuickActionCard(icon: Icons.map, label: 'Cari Driver', color: AppTheme.primary, onTap: _search),
                  const SizedBox(width: 12),
                  _QuickActionCard(icon: Icons.route, label: 'Rute Travel', color: AppTheme.secondary, onTap: _search),
                  const SizedBox(width: 12),
                  _QuickActionCard(icon: Icons.discount, label: 'Promo', color: Colors.green, onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),

              Text('Driver Tersedia', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              if (_isLoading)
                ...List.generate(3, (_) => const _DriverShimmer()),
              ..._drivers.map((d) => _DriverCard(
                driver: d,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => DriverDetailScreen(driverId: d['id']),
                )),
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final dynamic driver;
  final VoidCallback onTap;

  const _DriverCard({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = driver['user'] ?? {};
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary.withOpacity(0.1),
          child: Icon(Icons.person, color: AppTheme.primary),
        ),
        title: Text(user['fullname'] ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            const Icon(Icons.star, size: 16, color: AppTheme.secondary),
            const SizedBox(width: 4),
            Text('${(driver['rating'] ?? 0).toStringAsFixed(1)}'),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: driver['is_verified'] ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                driver['is_verified'] ? 'Terverifikasi' : 'Pending',
                style: TextStyle(
                  fontSize: 11,
                  color: driver['is_verified'] ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DriverShimmer extends StatelessWidget {
  const _DriverShimmer();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: const ListTile(
        leading: CircleAvatar(child: Icon(Icons.person)),
        title: Text('Memuat...', style: TextStyle(color: AppTheme.textSecondary)),
        subtitle: Text('...', style: TextStyle(color: AppTheme.textSecondary)),
      ),
    );
  }
}
