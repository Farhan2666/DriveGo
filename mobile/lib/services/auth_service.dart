import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> sendOtp(String phone) async {
    final res = await _api.post('/auth/otp/send', data: {'phone': phone});
    return res.data;
  }

  Future<Map<String, dynamic>> loginWithOtp(String phone, String otp) async {
    final res = await _api.post('/auth/login/otp', data: {
      'phone': phone,
      'otp_code': otp,
    });
    await _api.setToken(res.data['data']['token']);
    return res.data;
  }

  Future<Map<String, dynamic>> register({
    required String fullname,
    required String phone,
    String? email,
    required String password,
    String role = 'customer',
  }) async {
    final res = await _api.post('/auth/register', data: {
      'fullname': fullname,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
    });
    await _api.setToken(res.data['data']['token']);
    return res.data;
  }

  Future<Map<String, dynamic>> loginPassword(String phone, String password) async {
    final res = await _api.post('/auth/login', data: {
      'phone': phone,
      'password': password,
    });
    await _api.setToken(res.data['data']['token']);
    return res.data;
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {}
    await _api.clearToken();
  }

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _api.get('/auth/me');
    return res.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.put('/auth/profile', data: data);
    return res.data;
  }

  Future<void> updateFcmToken(String token) async {
    await _api.post('/auth/fcm-token', data: {'fcm_token': token});
  }
}
