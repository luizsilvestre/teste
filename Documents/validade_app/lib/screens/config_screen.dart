import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends StatefulWidget {
  final Function(String) onEmailSalvo;

  const ConfigScreen({Key? key, required this.onEmailSalvo}) : super(key: key);

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final _emailController = TextEditingController();
  bool _emailConfigurado = false;

  @override
  void initState() {
    super.initState();
    _carregarEmail();
  }

  Future<void> _carregarEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email_google_sheets') ?? '';

    if (email.isNotEmpty) {
      setState(() {
        _emailController.text = email;
        _emailConfigurado = true;
      });
    }
  }

  Future<void> _salvarEmail() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email não pode estar vazio!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_google_sheets', _emailController.text);

    setState(() {
      _emailConfigurado = true;
    });

    widget.onEmailSalvo(_emailController.text);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Email salvo com sucesso!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings, size: 80, color: Colors.blue),
            const SizedBox(height: 30),
            const Text(
              'Configure seu Email Google Sheets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Google',
                hintText: 'seu.email@gmail.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _salvarEmail,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 50,
                  vertical: 15,
                ),
                backgroundColor: Colors.blue.shade700,
              ),
              child: const Text(
                'Salvar Email',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            if (_emailConfigurado)
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Email: ${_emailController.text}',
                      style: const TextStyle(color: Colors.green, fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
