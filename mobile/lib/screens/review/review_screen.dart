import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ReviewScreen extends StatefulWidget {
  final int bookingId;
  final int driverId;

  const ReviewScreen({super.key, required this.bookingId, required this.driverId});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _api = ApiService();
  int _rating = 5;
  final _commentController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitReview() async {
    setState(() => _isLoading = true);
    try {
      await _api.post('/reviews', data: {
        'booking_id': widget.bookingId,
        'rating': _rating,
        'comment': _commentController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review berhasil dikirim')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim review'), backgroundColor: AppTheme.error),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beri Rating')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.star, size: 80, color: AppTheme.secondary),
            const SizedBox(height: 16),
            const Text('Bagaimana perjalanan Anda?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < _rating ? Icons.star : Icons.star_border,
                    size: 44,
                    color: AppTheme.secondary,
                  ),
                  onPressed: () => setState(() => _rating = i + 1),
                );
              }),
            ),

            const SizedBox(height: 8),
            Text(
              ['', 'Sangat Buruk', 'Buruk', 'Cukup', 'Baik', 'Sangat Baik'][_rating],
              style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 32),

            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Tulis ulasan Anda...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitReview,
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Kirim Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
