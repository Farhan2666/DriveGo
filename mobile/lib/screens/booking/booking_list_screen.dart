import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/booking_service.dart';
import '../../services/socket_service.dart';
import '../tracking/tracking_screen.dart';
import '../review/review_screen.dart';

class BookingListScreen extends StatefulWidget {
  const BookingListScreen({super.key});

  @override
  State<BookingListScreen> createState() => _BookingListScreenState();
}

class _BookingListScreenState extends State<BookingListScreen> {
  final _bookingService = BookingService();
  final _socketService = SocketService();
  List _bookings = [];
  bool _isLoading = true;
  String _activeTab = 'active';

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _socketService.bookingStream.listen((_) => _loadBookings());
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final params = _activeTab == 'active'
          ? {'status': 'waiting_payment,paid,driver_confirmed,driver_on_the_way,customer_picked_up,trip_started'}
          : {'status': 'trip_completed,cancelled,refund'};
      final res = await _bookingService.getBookings(params: params);
      setState(() => _bookings = res['data']['data'] ?? []);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String _statusLabel(String status) {
    return {
      'waiting_payment': 'Menunggu Pembayaran',
      'paid': 'Dibayar',
      'driver_confirmed': 'Driver Dikonfirmasi',
      'driver_on_the_way': 'Driver Menuju Lokasi',
      'customer_picked_up': 'Penumpang Dijemput',
      'trip_started': 'Perjalanan Dimulai',
      'trip_completed': 'Selesai',
      'cancelled': 'Dibatalkan',
      'refund': 'Refund',
    }[status] ?? status;
  }

  Color _statusColor(String status) {
    if (status == 'trip_completed') return AppTheme.success;
    if (status == 'cancelled' || status == 'refund') return AppTheme.error;
    if (status == 'waiting_payment') return AppTheme.secondary;
    return AppTheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Saya')),
      body: Column(
        children: [
          // Tabs
          Row(
            children: [
              _TabButton(label: 'Aktif', selected: _activeTab == 'active', onTap: () {
                setState(() { _activeTab = 'active'; _loadBookings(); });
              }),
              _TabButton(label: 'Riwayat', selected: _activeTab == 'history', onTap: () {
                setState(() { _activeTab = 'history'; _loadBookings(); });
              }),
            ],
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.book_online, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            const Text('Belum ada pesanan', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _bookings.length,
                          itemBuilder: (_, i) {
                            final b = _bookings[i];
                            final driver = b['driver']?['user'] ?? {};
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  final status = b['status'];
                                  if (status == 'trip_completed' && b['review'] == null) {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => ReviewScreen(bookingId: b['id'], driverId: b['driver_id']),
                                    ));
                                  } else if (status != 'cancelled' && status != 'refund') {
                                    Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => TrackingScreen(bookingId: b['id']),
                                    )).then((_) => _loadBookings());
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(b['booking_code'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _statusColor(b['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _statusLabel(b['status']),
                                              style: TextStyle(
                                                color: _statusColor(b['status']),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                                        const SizedBox(width: 4),
                                        Text(driver['fullname'] ?? 'Menunggu driver',
                                          style: const TextStyle(color: AppTheme.textSecondary)),
                                      ]),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.location_on, size: 16, color: AppTheme.error),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(b['pickup_location'] ?? '',
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                      const SizedBox(height: 4),
                                      Row(children: [
                                        const Icon(Icons.arrow_downward, size: 16, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(b['destination'] ?? '',
                                            style: const TextStyle(fontSize: 13),
                                            maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ]),
                                      const SizedBox(height: 8),
                                      Text('Rp ${(b['total_price'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppTheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppTheme.primary : AppTheme.textSecondary,
            )),
        ),
      ),
    );
  }
}
