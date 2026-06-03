import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/driver_service.dart';
import '../../services/booking_service.dart';
import '../booking/create_booking_screen.dart';
import '../review/review_list_screen.dart';

class DriverDetailScreen extends StatefulWidget {
  final int driverId;
  const DriverDetailScreen({super.key, required this.driverId});

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  final _driverService = DriverService();
  Map<String, dynamic>? _driver;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadDriver();
  }

  Future<void> _loadDriver() async {
    try {
      final res = await _driverService.getDriverDetail(widget.driverId);
      setState(() {
        _driver = res['data'];
        _isFavorite = res['data']['is_favorite'] ?? false;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await _driverService.toggleFavorite(widget.driverId);
      setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    }

    final driver = _driver;
    if (driver == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Driver tidak ditemukan')));
    }

    final user = driver['user'] ?? {};
    final vehicles = driver['vehicles'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(user['fullname'] ?? 'Driver'),
        actions: [
          IconButton(
            icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? AppTheme.error : null),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primary.withOpacity(0.1),
                    child: Icon(Icons.person, size: 48, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(user['fullname'] ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: AppTheme.secondary, size: 20),
                      const SizedBox(width: 4),
                      Text('${(driver['rating'] ?? 0).toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Text('(${driver['total_reviews'] ?? 0} ulasan)',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: driver['availability_status'] == 'available'
                          ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      driver['availability_status'] == 'available' ? 'Tersedia' : 'Sibuk',
                      style: TextStyle(
                        color: driver['availability_status'] == 'available' ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (driver['is_premium']) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: AppTheme.secondary),
                          SizedBox(width: 4),
                          Text('Driver Premium',
                            style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w500, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (driver['bio'] != null) ...[
              Text('Tentang', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(driver['bio'], style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 16),
            ],

            // Vehicles
            if (vehicles.isNotEmpty) ...[
              Text('Kendaraan', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...vehicles.map((v) => Card(
                child: ListTile(
                  leading: const Icon(Icons.directions_car, color: AppTheme.primary),
                  title: Text('${v['brand']} ${v['model']} (${v['year']})'),
                  subtitle: Text('${v['plate_number']} - ${v['color']} - ${v['capacity']} kursi'),
                ),
              )),
              const SizedBox(height: 16),
            ],

            // Stats
            Row(
              children: [
                _StatCard(icon: Icons.route, value: '${driver['total_orders'] ?? 0}', label: 'Perjalanan'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.star, value: driver['rating']?.toStringAsFixed(1) ?? '0', label: 'Rating'),
                const SizedBox(width: 12),
                _StatCard(icon: Icons.reviews, value: '${driver['total_reviews'] ?? 0}', label: 'Ulasan'),
              ],
            ),

            const SizedBox(height: 16),

            // Reviews section
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ReviewListScreen(driverId: widget.driverId),
              )),
              icon: const Icon(Icons.reviews),
              label: const Text('Lihat semua ulasan'),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: driver['availability_status'] == 'available'
                    ? () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CreateBookingScreen(driverId: widget.driverId, driverName: user['fullname']),
                      ))
                    : null,
                icon: const Icon(Icons.calendar_today),
                label: const Text('Pesan Driver Ini'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
