import 'api_service.dart';

class BookingService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    final res = await _api.post('/bookings', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getBookings({Map<String, dynamic>? params}) async {
    final res = await _api.get('/bookings', params: params);
    return res.data;
  }

  Future<Map<String, dynamic>> getBookingDetail(int id) async {
    final res = await _api.get('/bookings/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> updateBooking(int id, Map<String, dynamic> data) async {
    final res = await _api.put('/bookings/$id', data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> getHistory({Map<String, dynamic>? params}) async {
    final res = await _api.get('/bookings/history', params: params);
    return res.data;
  }

  Future<Map<String, dynamic>> calculatePrice(Map<String, dynamic> data) async {
    final res = await _api.post('/bookings/calculate-price', data: data);
    return res.data;
  }
}
