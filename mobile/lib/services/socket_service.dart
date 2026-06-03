import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StreamController<Map<String, dynamic>> _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _bookingController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _chatController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;
  Stream<Map<String, dynamic>> get bookingStream => _bookingController.stream;
  Stream<Map<String, dynamic>> get chatStream => _chatController.stream;
  Stream<Map<String, dynamic>> get notificationStream => _notificationController.stream;

  void connect(String token) {
    _socket = IO.io(AppConfig.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'auth': {'token': token},
    });

    _socket!.onConnect((_) {
      print('[Socket] Connected');
    });

    _socket!.on('driver:location', (data) {
      _locationController.add(data);
    });

    _socket!.on('booking:status:changed', (data) {
      _bookingController.add(data);
    });

    _socket!.on('chat:new_message', (data) {
      _chatController.add(data);
    });

    _socket!.on('notification:new', (data) {
      _notificationController.add(data);
    });

    _socket!.onDisconnect((_) {
      print('[Socket] Disconnected');
    });
  }

  void watchBooking(int bookingId) {
    _socket?.emit('booking:watch', bookingId);
  }

  void unwatchBooking(int bookingId) {
    _socket?.emit('booking:unwatch', bookingId);
  }

  void updateLocation(double lat, double lng, {double heading = 0}) {
    _socket?.emit('driver:location:update', {
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'speed': 0,
    });
  }

  void sendMessage(int receiverId, String message, {int? bookingId}) {
    _socket?.emit('chat:send', {
      'receiver_id': receiverId,
      'message': message,
      'booking_id': bookingId,
    });
  }

  void sendTyping(int receiverId, bool isTyping, {int? bookingId}) {
    _socket?.emit('chat:typing', {
      'receiver_id': receiverId,
      'is_typing': isTyping,
      'booking_id': bookingId,
    });
  }

  void sendSos(double lat, double lng, {int? bookingId}) {
    _socket?.emit('emergency:sos', {
      'lat': lat,
      'lng': lng,
      'booking_id': bookingId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }

  void dispose() {
    _locationController.close();
    _bookingController.close();
    _chatController.close();
    _notificationController.close();
    disconnect();
  }
}
