import 'package:flutter/material.dart';
import '../../config/theme.dart';

class PaymentScreen extends StatefulWidget {
  final int bookingId;
  final double totalPrice;
  final String bookingCode;

  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.totalPrice,
    required this.bookingCode,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;

  final List<Map<String, dynamic>> _methods = [
    {'id': 'qris', 'name': 'QRIS', 'icon': Icons.qr_code, 'color': Colors.purple},
    {'id': 'ovo', 'name': 'OVO', 'icon': Icons.account_balance_wallet, 'color': Colors.purple},
    {'id': 'dana', 'name': 'DANA', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
    {'id': 'gopay', 'name': 'GoPay', 'icon': Icons.account_balance_wallet, 'color': Colors.green},
    {'id': 'transfer_bank', 'name': 'Transfer Bank', 'icon': Icons.account_balance, 'color': Colors.indigo},
  ];

  Future<void> _pay() async {
    if (_selectedMethod == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Panggil API payment
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.pop(context); // dismiss loading
        _showSuccess();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembayaran gagal'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
            const SizedBox(height: 16),
            const Text('Pembayaran Berhasil!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Booking ${widget.bookingCode} telah dikonfirmasi'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Booking info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt, color: AppTheme.primary, size: 40),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Booking ${widget.bookingCode}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Text('Menunggu pembayaran',
                              style: TextStyle(color: AppTheme.secondary, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.8)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Total Pembayaran',
                          style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(
                          'Rp ${widget.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}',
                          style: const TextStyle(
                            color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Text('Pilih Metode Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  ..._methods.map((m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: RadioListTile<String>(
                      value: m['id'],
                      groupValue: _selectedMethod,
                      onChanged: (v) => setState(() => _selectedMethod = v),
                      title: Text(m['name']),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (m['color'] as Color).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(m['icon'], color: m['color']),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),

          // Bottom button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMethod == null ? null : _pay,
                  child: const Text('Bayar Sekarang'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
