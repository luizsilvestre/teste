import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';
import 'cadastro_screen.dart';
import 'lista_screen.dart';

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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                  const SnackBar(
                    content: Text('Email não pode estar vazio!'),
                  ),
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
    List<Widget> telas = [
      CadastroScreen(
        dbHelper: dbHelper,
        onMedicamentoAdicionado: _atualizarLista,
      ),
      ListaScreen(
        medicamentos: _medicamentos,
        dbHelper: dbHelper,
        onMedicamentoDeletado: _atualizarLista,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Validade'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: 'Alterar Email',
              child: GestureDetector(
                onTap: _mostrarDialogoAlterarEmail,
                child: const Icon(
                  Icons.email,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
      body: telas[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          if (index == 1) {
            _atualizarLista();
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Cadastro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lista',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
