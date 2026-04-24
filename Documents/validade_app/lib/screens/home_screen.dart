import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';
import 'cadastro_screen.dart';
import 'lista_screen.dart';
import 'alertas_screen.dart';
import 'categorias_screen.dart';

class HomeScreen extends StatefulWidget {
  final String email;

  const HomeScreen({Key? key, required this.email}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final dbHelper = DBHelper();
  List<Medicamento> _medicamentos = [];
  late String _emailAtual;

  @override
  void initState() {
    super.initState();
    _emailAtual = widget.email;
    _carregarMedicamentos();
  }

  Future<void> _carregarMedicamentos() async {
    final medicamentos = await dbHelper.buscarTodos();
    setState(() {
      _medicamentos = medicamentos;
    });
  }

  void _atualizarLista() {
    _carregarMedicamentos();
  }

  void _mostrarDialogoAlterarEmail() {
    final emailController = TextEditingController(text: _emailAtual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alterar Email'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Novo Email',
            hintText: 'seu.email@gmail.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email não pode estar vazio!')),
                );
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString(
                'email_google_sheets',
                emailController.text,
              );

              setState(() {
                _emailAtual = emailController.text;
              });

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email alterado com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> telas = [
      CadastroScreen(
        dbHelper: dbHelper,
        onMedicamentoAdicionado: _atualizarLista,
      ),
      ListaScreen(
        medicamentos: _medicamentos,
        dbHelper: dbHelper,
        onMedicamentoDeletado: _atualizarLista,
      ),
      CategoriasScreen(dbHelper: dbHelper),
      AlertasScreen(dbHelper: dbHelper),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Controle de Validade',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade700,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Alterar Email',
              child: GestureDetector(
                onTap: _mostrarDialogoAlterarEmail,
                child: const Icon(Icons.email, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
      body: telas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // essencial com 4+ itens
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _atualizarLista();
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Cadastro'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Lista'),
          BottomNavigationBarItem(icon: Icon(Icons.label_outline), label: 'Categorias'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: 'Alertas'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
