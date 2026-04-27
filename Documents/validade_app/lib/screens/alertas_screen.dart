import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';

// ===== SERVIÇO DE NOTIFICAÇÕES =====
// Singleton para gerenciar notificações locais em todo o app
class NotificacaoService {
  static final NotificacaoService _instance = NotificacaoService._internal();
  factory NotificacaoService() => _instance;
  NotificacaoService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Inicializa o plugin — deve ser chamado no main.dart
  Future<void> inicializar() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);
  }

  // Solicita permissão de notificação (Android 13+)
  Future<void> solicitarPermissao() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  // Envia uma notificação imediata
  Future<void> enviarNotificacao({
    required int id,
    required String titulo,
    required String corpo,
    required String canal,
    required Color cor,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      canal,
      canal,
      importance: Importance.high,
      priority: Priority.high,
      color: cor,
      styleInformation: BigTextStyleInformation(corpo),
    );

    await _plugin.show(
      id,
      titulo,
      corpo,
      NotificationDetails(android: androidDetails),
    );
  }

  // Cancela todas as notificações
  Future<void> cancelarTodas() async {
    await _plugin.cancelAll();
  }
}

// ===== TELA DE ALERTAS =====
class AlertasScreen extends StatefulWidget {
  final DBHelper dbHelper;

  const AlertasScreen({Key? key, required this.dbHelper}) : super(key: key);

  @override
  State<AlertasScreen> createState() => _AlertasScreenState();
}

class _AlertasScreenState extends State<AlertasScreen> {
  List<Medicamento> _vencidos = [];
  List<Medicamento> _urgentes = [];
  List<Medicamento> _atencao = [];
  bool _carregando = true;
  bool _notificacoesAtivas = false;

  final _notificacaoService = NotificacaoService();

  @override
  void initState() {
    super.initState();
    _inicializarNotificacoes();
    _carregarMedicamentos();
  }

  // Inicializa e solicita permissão de notificação
  Future<void> _inicializarNotificacoes() async {
    await _notificacaoService.inicializar();
    await _notificacaoService.solicitarPermissao();
    setState(() => _notificacoesAtivas = true);
  }

  // Carrega e classifica os medicamentos por urgência
  Future<void> _carregarMedicamentos() async {
    setState(() => _carregando = true);
    final todos = await widget.dbHelper.buscarTodos();
    final agora = DateTime.now();

    List<Medicamento> vencidos = [];
    List<Medicamento> urgentes = [];
    List<Medicamento> atencao = [];

    for (final med in todos) {
      try {
        final partes = med.dataVencimento.split('/');
        final data = DateTime(
          int.parse(partes[2]),
          int.parse(partes[1]),
          int.parse(partes[0]),
        );
        final dias = data.difference(agora).inDays;

        if (dias < 0) {
          vencidos.add(med);
        } else if (dias <= 30) {
          urgentes.add(med);
        } else if (dias <= 90) {
          atencao.add(med);
        }
      } catch (_) {}
    }

    setState(() {
      _vencidos = vencidos;
      _urgentes = urgentes;
      _atencao = atencao;
      _carregando = false;
    });
  }

  // Envia notificação para um produto específico
  Future<void> _notificar(Medicamento med, Color cor) async {
    final partes = med.dataVencimento.split('/');
    final data = DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
    final dias = data.difference(DateTime.now()).inDays;

    final titulo = dias < 0
        ? '🔴 PRODUTO VENCIDO'
        : dias <= 30
        ? '🟠 Vencimento Urgente'
        : '🟡 Atenção ao Vencimento';

    final corpo = dias < 0
        ? '${med.produto} (Lote: ${med.lote}) está vencido há ${dias.abs()} dias!'
        : '${med.produto} (Lote: ${med.lote}) vence em $dias dias — ${med.dataVencimento}';

    await _notificacaoService.enviarNotificacao(
      id: med.id ?? 0,
      titulo: titulo,
      corpo: corpo,
      canal: dias < 0
          ? 'vencidos'
          : dias <= 30
          ? 'urgentes'
          : 'atencao',
      cor: cor,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔔 Notificação enviada!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Envia notificações para TODOS os produtos com problema
  Future<void> _notificarTodos() async {
    int count = 0;

    for (final med in _vencidos) {
      await _notificar(med, Colors.red);
      count++;
    }
    for (final med in _urgentes) {
      await _notificar(med, Colors.orange);
      count++;
    }
    for (final med in _atencao) {
      await _notificar(med, Colors.yellow.shade700);
      count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔔 $count notificações enviadas!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _vencidos.length + _urgentes.length + _atencao.length;

    return _carregando
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _carregarMedicamentos,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ===== HEADER =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Alertas de Vencimento',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    // Botão notificar todos
                    if (total > 0)
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_active,
                          color: Colors.blue,
                        ),
                        tooltip: 'Notificar todos',
                        onPressed: _notificarTodos,
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== CARDS DE RESUMO =====
                Row(
                  children: [
                    _resumoCard('Vencidos', _vencidos.length, Colors.red),
                    const SizedBox(width: 8),
                    _resumoCard('Urgentes', _urgentes.length, Colors.orange),
                    const SizedBox(width: 8),
                    _resumoCard(
                      'Atenção',
                      _atencao.length,
                      Colors.yellow.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ===== TUDO EM DIA =====
                if (total == 0)
                  Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tudo em dia! ✅',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum produto vencido ou vencendo em breve.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // ===== VENCIDOS =====
                if (_vencidos.isNotEmpty) ...[
                  _secaoTitulo('🔴 Vencidos', Colors.red),
                  ..._vencidos.map((m) => _cardAlerta(m, Colors.red)),
                ],

                // ===== URGENTES =====
                if (_urgentes.isNotEmpty) ...[
                  _secaoTitulo('🟠 Urgente (até 30 dias)', Colors.orange),
                  ..._urgentes.map((m) => _cardAlerta(m, Colors.orange)),
                ],

                // ===== ATENÇÃO =====
                if (_atencao.isNotEmpty) ...[
                  _secaoTitulo(
                    '🟡 Atenção (31–90 dias)',
                    Colors.yellow.shade700,
                  ),
                  ..._atencao.map(
                    (m) => _cardAlerta(m, Colors.yellow.shade700),
                  ),
                ],
              ],
            ),
          );
  }

  // ===== WIDGETS AUXILIARES =====

  Widget _resumoCard(String label, int count, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cor, width: 1.5),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: cor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _secaoTitulo(String titulo, Color cor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        titulo,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cor),
      ),
    );
  }

  Widget _cardAlerta(Medicamento med, Color cor) {
    final partes = med.dataVencimento.split('/');
    final data = DateTime(
      int.parse(partes[2]),
      int.parse(partes[1]),
      int.parse(partes[0]),
    );
    final dias = data.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: cor.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor.withOpacity(0.15),
          child: Icon(Icons.warning_amber_rounded, color: cor),
        ),
        title: Text(
          med.produto,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Lote: ${med.lote} • ${med.dataVencimento}\n'
          '${dias < 0 ? "Vencido há ${dias.abs()} dias" : "Restam $dias dias"}',
          style: TextStyle(color: cor, fontWeight: FontWeight.w500),
        ),
        isThreeLine: true,
        // Botão de notificar produto individual
        trailing: IconButton(
          icon: const Icon(Icons.notifications_outlined),
          color: cor,
          tooltip: 'Notificar',
          onPressed: () => _notificar(med, cor),
        ),
      ),
    );
  }
}
