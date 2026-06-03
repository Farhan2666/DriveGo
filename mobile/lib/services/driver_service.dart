import 'api_service.dart';

class DriverService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> getDrivers({Map<String, dynamic>? params}) async {
    final res = await _api.get('/drivers', params: params);
    return res.data;
  }

  Future<Map<String, dynamic>> searchDrivers({Map<String, dynamic>? params}) async {
    final res = await _api.get('/drivers/search', params: params);
    return res.data;
  }

  Future<Map<String, dynamic>> getDriverDetail(int id) async {
    final res = await _api.get('/drivers/$id');
    return res.data;
  }

  Future<Map<String, dynamic>> toggleFavorite(int id) async {
    final res = await _api.post('/drivers/$id/favorite');
    return res.data;
  }

  Future<Map<String, dynamic>> getFavorites() async {
    final res = await _api.get('/favorites');
    return res.data;
  }

  Future<Map<String, dynamic>> updateAvailability(String status) async {
    final res = await _api.put('/driver/availability', data: {'status': status});
    return res.data;
  }

  Future<Map<String, dynamic>> updateLocation(double lat, double lng) async {
    final res = await _api.post('/driver/location', data: {'lat': lat, 'lng': lng});
    return res.data;
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final res = await _api.get('/driver/statistics');
    return res.data;
  }
}
