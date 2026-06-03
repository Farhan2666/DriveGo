import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/main_screen.dart';
import 'services/auth_service.dart';
import 'services/socket_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DriveGoApp());
}

class DriveGoApp extends StatelessWidget {
  const DriveGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DriveGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _authService = AuthService();
  bool _checking = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _authService.getToken();
    if (token != null) {
      SocketService().connect(token);
      setState(() => _isLoggedIn = true);
    }
    setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isLoggedIn ? const MainScreen() : const LoginScreen();
  }
}
