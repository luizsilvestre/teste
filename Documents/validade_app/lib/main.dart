import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/config_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Validade',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _emailConfigurado;

  @override
  void initState() {
    super.initState();
    _verificarEmail();
  }

  Future<void> _verificarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email_google_sheets');
    
    setState(() {
      _emailConfigurado = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_emailConfigurado == null) {
      return ConfigScreen(
        onEmailSalvo: (email) {
          setState(() {
            _emailConfigurado = email;
          });
        },
      );
    }

    return HomeScreen(email: _emailConfigurado!);
  }
}
