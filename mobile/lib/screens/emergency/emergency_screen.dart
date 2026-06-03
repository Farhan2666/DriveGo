import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/socket_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _sendSos() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kirim Sinyal SOS?'),
        content: const Text('Lokasi darurat Anda akan dikirim ke tim DriveGo dan driver.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Kirim SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      SocketService().sendSos(-6.2, 106.8); // Replace with actual GPS

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, size: 64, color: AppTheme.success),
              const SizedBox(height: 16),
              const Text('Sinyal SOS Terkirim!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Tim DriveGo akan segera menghubungi Anda.',
                textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Darurat'),
        backgroundColor: AppTheme.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Dalam keadaan darurat?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Tekan tombol SOS untuk mengirim lokasi Anda',
              style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 48),

            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.1);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: _sendSos,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppTheme.error, Color(0xFFDC2626)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.error.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sos, color: Colors.white, size: 48),
                      SizedBox(height: 8),
                      Text('SOS', style: TextStyle(
                        color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      Text('Tekan untuk kirim', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),
            const Text('Atau hubungi nomor darurat:',
              style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 8),
            const Text('119', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
