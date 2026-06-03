import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/driver_service.dart';
import '../../services/booking_service.dart';
import '../payment/payment_screen.dart';

class CreateBookingScreen extends StatefulWidget {
  final int? driverId;
  final String? driverName;
  final String? searchQuery;

  const CreateBookingScreen({super.key, this.driverId, this.driverName, this.searchQuery});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _driverService = DriverService();
  final _bookingService = BookingService();
  final _pickupController = TextEditingController();
  final _destController = TextEditingController();

  Map<String, dynamic>? _selectedDriver;
  Map<String, dynamic>? _selectedVehicle;
  List _drivers = [];
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = true;
  bool _isCalculating = false;
  bool _showSearch = true;

  double _basePrice = 0;
  double _distancePrice = 0;
  double _serviceFee = 0;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    try {
      final res = await _driverService.searchDrivers();
      setState(() {
        _drivers = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _calculatePrice() async {
    if (_pickupController.text.isEmpty || _destController.text.isEmpty) return;

    setState(() => _isCalculating = true);
    try {
      final res = await _bookingService.calculatePrice({
        'pickup_lat': -6.2,
        'pickup_lng': 106.8,
        'dest_lat': -6.3,
        'dest_lng': 106.9,
      });
      setState(() {
        _basePrice = res['data']['base_price'] ?? 0;
        _distancePrice = res['data']['distance_price'] ?? 0;
        _serviceFee = res['data']['service_fee'] ?? 0;
        _totalPrice = res['data']['total_price'] ?? 0;
      });
    } catch (_) {}
    setState(() => _isCalculating = false);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime);
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _createBooking() async {
    if (_selectedDriver == null || _pickupController.text.isEmpty || _destController.text.isEmpty) return;

    try {
      final res = await _bookingService.createBooking({
        'driver_id': _selectedDriver!['id'],
        'vehicle_id': _selectedVehicle?['id'],
        'pickup_location': _pickupController.text,
        'pickup_lat': -6.2,
        'pickup_lng': 106.8,
        'destination': _destController.text,
        'dest_lat': -6.3,
        'dest_lng': 106.9,
        'booking_date': _selectedDate.toIso8601String().split('T')[0],
        'booking_time': '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PaymentScreen(
            bookingId: res['data']['id'],
            totalPrice: _totalPrice,
            bookingCode: res['data']['booking_code'],
          ),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat booking'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.driverName ?? 'Pesan Driver')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pickup
            const Text('Lokasi Penjemputan', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _pickupController,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat jemput',
                prefixIcon: Icon(Icons.trip_origin, color: Colors.green),
              ),
              onChanged: (_) => _calculatePrice(),
            ),
            const SizedBox(height: 16),

            // Destination
            const Text('Tujuan', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _destController,
              decoration: const InputDecoration(
                hintText: 'Masukkan alamat tujuan',
                prefixIcon: Icon(Icons.location_on, color: AppTheme.error),
              ),
              onChanged: (_) => _calculatePrice(),
            ),
            const SizedBox(height: 24),

            // Driver selection
            const Text('Pilih Driver', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _drivers.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final d = _drivers[i];
                        final isSelected = _selectedDriver?['id'] == d['id'];
                        final user = d['user'] ?? {};
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedDriver = d;
                            _selectedVehicle = (d['vehicles'] as List?)?.isNotEmpty == true
                                ? d['vehicles'][0] : null;
                          }),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border, width: isSelected ? 2 : 1),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person, color: isSelected ? AppTheme.primary : AppTheme.textSecondary),
                                Text(user['fullname']?.toString().split(' ').first ?? '',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isSelected ? AppTheme.primary : null)),
                                Text('${(d['rating'] ?? 0).toStringAsFixed(1)} ★',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.secondary)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Jam', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(
                          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Price breakdown
            if (_totalPrice > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    _PriceRow(label: 'Harga Dasar', value: _basePrice),
                    _PriceRow(label: 'Biaya Jarak', value: _distancePrice),
                    _PriceRow(label: 'Biaya Layanan', value: _serviceFee),
                    const Divider(),
                    _PriceRow(label: 'Total', value: _totalPrice, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (_isCalculating)
              const Center(child: CircularProgressIndicator()),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedDriver != null && _pickupController.text.isNotEmpty && _destController.text.isNotEmpty
                    ? _createBooking : null,
                icon: const Icon(Icons.check_circle),
                label: const Text('Konfirmasi Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destController.dispose();
    super.dispose();
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final double value;
  final bool bold;

  const _PriceRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? AppTheme.textPrimary : AppTheme.textSecondary,
          )),
          Text('Rp ${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
            style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }
}
