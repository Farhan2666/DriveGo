import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/booking_service.dart';
import '../../services/socket_service.dart';
import '../../services/api_service.dart';
import '../emergency/emergency_screen.dart';
import '../chat/chat_screen.dart';

class TrackingScreen extends StatefulWidget {
  final int bookingId;
  const TrackingScreen({super.key, required this.bookingId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _bookingService = BookingService();
  final _socketService = SocketService();
  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _driver;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _socketService.watchBooking(widget.bookingId);

    _socketService.locationStream.listen((data) {
      if (mounted) setState(() {
        _driver?['lat'] = data['lat'];
        _driver?['lng'] = data['lng'];
      });
    });

    _socketService.bookingStream.listen((data) {
      if (data['booking_id'] == widget.bookingId) {
        _loadBooking();
      }
    });
  }

  Future<void> _loadBooking() async {
    try {
      final res = await _bookingService.getBookingDetail(widget.bookingId);
      setState(() {
        _booking = res['data'];
        _driver = _booking?['driver'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan?'),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Ya, Batalkan')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _bookingService.updateBooking(widget.bookingId, {
          'action': 'cancel',
          'reason': 'Dibatalkan oleh pelanggan',
        });
        _loadBooking();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _socketService.unwatchBooking(widget.bookingId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));

    final booking = _booking;
    if (booking == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('Booking tidak ditemukan')));

    final driverUser = _driver?['user'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking ${booking['booking_code'] ?? ''}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: AppTheme.error),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const EmergencyScreen(),
            )),
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatScreen(
                bookingId: widget.bookingId,
                driverName: driverUser['fullname'] ?? 'Driver',
                driverId: _driver?['user_id'],
              ),
            )),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primary.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(_statusLabel(booking['status']),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Map placeholder
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.map, size: 48, color: AppTheme.textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 8),
                          const Text('Peta Live Tracking', style: TextStyle(color: AppTheme.textSecondary)),
                          Text('${_driver?['lat'] ?? '-'}, ${_driver?['lng'] ?? '-'}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Driver info
                  if (_driver != null) ...[
                    Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: const Icon(Icons.person, color: AppTheme.primary),
                        ),
                        title: Text(driverUser['fullname'] ?? 'Driver',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Row(
                          children: [
                            const Icon(Icons.star, size: 14, color: AppTheme.secondary),
                            const SizedBox(width: 4),
                            Text('${(_driver?['rating'] ?? 0).toStringAsFixed(1)}'),
                          ],
                        ),
                        trailing: TextButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              bookingId: widget.bookingId,
                              driverName: driverUser['fullname'] ?? 'Driver',
                              driverId: _driver?['user_id'],
                            ),
                          )),
                          child: const Text('Chat'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location info
                  _LocationInfo(
                    icon: Icons.trip_origin,
                    iconColor: Colors.green,
                    label: 'Penjemputan',
                    address: booking['pickup_location'] ?? '',
                  ),
                  _LocationInfo(
                    icon: Icons.location_on,
                    iconColor: AppTheme.error,
                    label: 'Tujuan',
                    address: booking['destination'] ?? '',
                  ),
                  const SizedBox(height: 16),

                  // Booking details
                  _DetailRow(label: 'Tanggal', value: booking['booking_date'] ?? ''),
                  _DetailRow(label: 'Jam', value: booking['booking_time'] ?? ''),
                  _DetailRow(label: 'Total', value: 'Rp ${(booking['total_price'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}', bold: true),
                ],
              ),
            ),
          ),

          // Action buttons
          if (booking['can_cancel'] ?? booking['status'] == 'waiting_payment' || booking['status'] == 'paid')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _cancelBooking,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Batalkan Pesanan'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.error),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(String status) {
    return {
      'waiting_payment': 'Menunggu Pembayaran',
      'paid': 'Dibayar - Menunggu Konfirmasi Driver',
      'driver_confirmed': 'Driver Dikonfirmasi',
      'driver_on_the_way': 'Driver Menuju Lokasi',
      'customer_picked_up': 'Penumpang Sudah Dijemput',
      'trip_started': 'Perjalanan Dimulai',
      'trip_completed': 'Perjalanan Selesai',
      'cancelled': 'Dibatalkan',
      'refund': 'Refund',
    }[status] ?? status;
  }
}

class _LocationInfo extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String address;

  const _LocationInfo({required this.icon, required this.iconColor, required this.label, required this.address});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(address, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500)),
        ],
      ),
    );
  }
}
