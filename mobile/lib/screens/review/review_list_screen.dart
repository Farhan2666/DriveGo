import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class ReviewListScreen extends StatefulWidget {
  final int driverId;
  const ReviewListScreen({super.key, required this.driverId});

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  final _api = ApiService();
  List _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final res = await _api.get('/reviews', params: {'driver_id': widget.driverId});
      setState(() {
        _reviews = res.data['data']['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ulasan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reviews.isEmpty
              ? const Center(child: Text('Belum ada ulasan'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (_, i) {
                    final r = _reviews[i];
                    final customer = r['customer'] ?? {};
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: Icon(Icons.person, color: AppTheme.primary, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(customer['fullname'] ?? 'Customer',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Row(
                                  children: List.generate(5, (j) {
                                    return Icon(
                                      j < (r['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: AppTheme.secondary,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (r['comment'] != null) ...[
                              const SizedBox(height: 8),
                              Text(r['comment'], style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
