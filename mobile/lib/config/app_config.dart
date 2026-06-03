class AppConfig {
  static const String appName = 'DriveGo';
  static const String baseUrl = 'https://api.drivego.app/api';
  static const String socketUrl = 'https://realtime.drivego.app';
  static const String primaryColor = '#2563EB';
  static const String secondaryColor = '#F59E0B';

  static const String googleMapsKey = 'YOUR_GOOGLE_MAPS_KEY';
  static const String midtransClientKey = 'YOUR_MIDTRANS_CLIENT_KEY';

  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration locationUpdateInterval = Duration(seconds: 5);
}
