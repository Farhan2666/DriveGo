import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'chat_screen.dart';

class ChatConversationScreen extends StatefulWidget {
  const ChatConversationScreen({super.key});

  @override
  State<ChatConversationScreen> createState() => _ChatConversationScreenState();
}

class _ChatConversationScreenState extends State<ChatConversationScreen> {
  final _api = ApiService();
  List _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final res = await _api.get('/messages/conversations');
      setState(() {
        _conversations = res.data['data'] ?? [];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pesan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, size: 64, color: AppTheme.textSecondary.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      const Text('Belum ada chat', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _conversations.length,
                  itemBuilder: (_, i) {
                    final msg = _conversations[i];
                    final otherUser = msg['sender_id'] != /* current user id */ 0
                        ? msg['sender'] : msg['receiver'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        child: Icon(Icons.person, color: AppTheme.primary),
                      ),
                      title: Text(otherUser?['fullname'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(msg['message'] ?? '',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: msg['is_read'] == false ? AppTheme.textPrimary : AppTheme.textSecondary)),
                      trailing: Text(
                        _formatTime(msg['created_at'] ?? ''),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          driverName: otherUser?['fullname'] ?? 'User',
                          driverId: otherUser?['id'],
                        ),
                      )).then((_) => _loadConversations()),
                    );
                  },
                ),
    );
  }

  String _formatTime(String dateStr) {
    if (dateStr.length < 16) return '';
    return dateStr.substring(11, 16);
  }
}
