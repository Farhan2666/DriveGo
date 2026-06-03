import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int? bookingId;
  final String driverName;
  final int? driverId;

  const ChatScreen({
    super.key,
    this.bookingId,
    required this.driverName,
    this.driverId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = ApiService();
  final _socketService = SocketService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List _messages = [];
  bool _isLoading = true;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _socketService.chatStream.listen((data) {
      if (mounted) {
        setState(() => _messages.add(data));
        _scrollToBottom();
      }
    });
  }

  Future<void> _loadMessages() async {
    try {
      final params = <String, dynamic>{'booking_id': widget.bookingId};
      if (widget.driverId != null) {
        params['other_user_id'] = widget.driverId;
      }
      final res = await _api.get('/messages', params: params);
      setState(() {
        _messages = res.data['data']['data'] ?? [];
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || widget.driverId == null) return;

    _messageController.clear();
    _socketService.sendMessage(widget.driverId!, text, bookingId: widget.bookingId);

    setState(() {
      _messages.add({
        'sender_id': 0, // current user
        'message': text,
        'message_type': 'text',
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
      });
    });
    _scrollToBottom();

    // Save via API
    _api.post('/messages', data: {
      'receiver_id': widget.driverId,
      'message': text,
      'booking_id': widget.bookingId,
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.driverName)),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _messages.length && _isTyping) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Mengetik', style: TextStyle(color: AppTheme.textSecondary)),
                              const SizedBox(width: 8),
                              _TypingIndicator(),
                            ],
                          ),
                        );
                      }

                      final msg = _messages[i];
                      final isMe = msg['sender_id'] == 0 || msg['sender_id'] == msg['sender_id'];

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isMe ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16).copyWith(
                              bottomRight: isMe ? const Radius.circular(4) : null,
                              bottomLeft: !isMe ? const Radius.circular(4) : null,
                            ),
                            border: !isMe ? Border.all(color: AppTheme.border) : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(msg['message'] ?? '',
                                style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(msg['created_at'] ?? ''),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isMe ? Colors.white70 : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Ketik pesan...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppTheme.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: AppTheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateStr) {
    if (dateStr.length < 16) return '';
    return '${dateStr.substring(11, 13)}.${dateStr.substring(14, 16)}';
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, child) {
            final delay = i * 200;
            final value = (_controller.value * 1200 - delay).clamp(0, 600).toDouble();
            final size = 6.0 + (value / 600 * 6);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppTheme.textSecondary,
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
