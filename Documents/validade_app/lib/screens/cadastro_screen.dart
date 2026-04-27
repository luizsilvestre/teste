import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../database/db_helper.dart';
import '../models/medicamento.dart';

// ===== MAIN REGISTRATION SCREEN =====
// Allows manual product registration or via barcode scanner
class CadastroScreen extends StatefulWidget {
  final DBHelper dbHelper;
  final Function onMedicamentoAdicionado;

  const CadastroScreen({
    Key? key,
    required this.dbHelper,
    required this.onMedicamentoAdicionado,
  }) : super(key: key);

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // Text controllers for manual input fields
  final _produtoController = TextEditingController();
  final _loteController = TextEditingController();

  DateTime? _dataVencimento;
  bool _carregando = false;
  String? _codigoBarras;
  String? _fotoPath;

  // Categories loaded from database
  List<Map<String, dynamic>> _categorias = [];
  int? _categoriaSelecionadaId;

  @override
  void initState() {
    super.initState();
    _carregarCategorias();
  }

  // Loads categories from database on screen init
  Future<void> _carregarCategorias() async {
    final categorias = await widget.dbHelper.buscarCategorias();
    setState(() {
      _categorias = categorias;
      if (categorias.isNotEmpty) {
        _categoriaSelecionadaId = categorias.first['id'] as int;
      }
    });
  }

  // Opens barcode scanner and shows registration form after scan
  Future<void> _abrirScanner() async {
    final resultado = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _ScannerPage()),
    );

    if (resultado != null && resultado.isNotEmpty) {
      setState(() => _codigoBarras = resultado);
      _mostrarFormularioCadastro();
    }
  }

  // Takes a photo using device camera
  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (imagem != null) setState(() => _fotoPath = imagem.path);
  }

  // Picks a photo from device gallery
  Future<void> _escolherDaGaleria() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (imagem != null) setState(() => _fotoPath = imagem.path);
  }

  // Opens bottom sheet form after barcode is scanned
  void _mostrarFormularioCadastro() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // prevents white screen when keyboard opens
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCadastro(
        codigoBarras: _codigoBarras,
        fotoPath: _fotoPath,
        categorias: _categorias,
        categoriaSelecionadaId: _categoriaSelecionadaId,
        dbHelper: widget.dbHelper,
        onSalvo: () {
          widget.onMedicamentoAdicionado();
          setState(() {
            _codigoBarras = null;
            _fotoPath = null;
          });
        },
      ),
    );
  }

  // Saves product manually entered via form fields
  Future<void> _salvarMedicamento() async {
    if (_produtoController.text.isEmpty ||
        _loteController.text.isEmpty ||
        _dataVencimento == null ||
        _categoriaSelecionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      final medicamento = Medicamento(
        categoriaId: _categoriaSelecionadaId!,
        produto: _produtoController.text,
        lote: _loteController.text,
        dataVencimento: DateFormat('dd/MM/yyyy').format(_dataVencimento!),
        criadoEm: DateTime.now(),
        codigoBarras: _codigoBarras,
        foto: _fotoPath,
      );

      await widget.dbHelper.inserir(medicamento);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produto salvo com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset all fields after saving
      _produtoController.clear();
      _loteController.clear();
      setState(() {
        _dataVencimento = null;
        _codigoBarras = null;
        _fotoPath = null;
        _categoriaSelecionadaId =
            _categorias.isNotEmpty ? _categorias.first['id'] as int : null;
      });

      widget.onMedicamentoAdicionado();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  // Opens native date picker dialog
  Future<void> _selecionarData() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dataVencimento = picked);
  }

  // Shows bottom sheet with photo options (camera, gallery, remove)
  void _mostrarOpcoesFoto() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar foto'),
              onTap: () {
                Navigator.pop(context);
                _tirarFoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da galeria'),
              onTap: () {
                Navigator.pop(context);
                _escolherDaGaleria();
              },
            ),
            if (_fotoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover foto',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _fotoPath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // Converts hex color string to Flutter Color object
  Color _hexParaColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Adicionar Produto',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 30),

          // ===== BARCODE SCANNER BUTTON =====
          GestureDetector(
            onTap: _abrirScanner,
            child: Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner,
                      size: 64, color: Colors.blue.shade700),
                  const SizedBox(height: 12),
                  Text(
                    'Escanear Codigo de Barras',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toque para abrir a camera',
                    style: TextStyle(fontSize: 13, color: Colors.blue.shade400),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Divider between scanner and manual entry
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('ou cadastre manualmente',
                    style: TextStyle(color: Colors.grey)),
              ),
              Expanded(child: Divider()),
            ],
          ),

          const SizedBox(height: 24),

          // ===== CATEGORY DROPDOWN =====
          if (_categorias.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<int>(
              value: _categoriaSelecionadaId,
              decoration: InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.category),
              ),
              items: _categorias.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'] as int,
                  child: Row(
                    children: [
                      // Color indicator dot
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: _hexParaColor(cat['cor'] as String),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(cat['nome'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _categoriaSelecionadaId = v),
            ),

          const SizedBox(height: 16),

          // ===== PRODUCT NAME + PHOTO BUTTON =====
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _produtoController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Produto',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    prefixIcon: const Icon(Icons.local_pharmacy),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Photo button — shows thumbnail if photo is selected
              InkWell(
                onTap: _mostrarOpcoesFoto,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _fotoPath != null
                        ? Colors.green
                        : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _fotoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child:
                              Image.file(File(_fotoPath!), fit: BoxFit.cover),
                        )
                      : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 28),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ===== LOT NUMBER FIELD =====
          TextField(
            controller: _loteController,
            decoration: InputDecoration(
              labelText: 'Lote',
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.numbers),
            ),
          ),

          const SizedBox(height: 16),

          // ===== EXPIRY DATE PICKER =====
          GestureDetector(
            onTap: _selecionarData,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    _dataVencimento == null
                        ? 'Selecione a data de vencimento'
                        : 'Vence: ${DateFormat('dd/MM/yyyy').format(_dataVencimento!)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: _dataVencimento == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ===== SAVE BUTTON =====
          ElevatedButton(
            onPressed: _carregando ? null : _salvarMedicamento,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade700,
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _carregando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Salvar Produto',
                    style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _loteController.dispose();
    super.dispose();
  }
}

// ===== POST-SCAN REGISTRATION FORM =====
// Bottom sheet shown after barcode is scanned
// User fills in product name, category, lot and expiry date
class _FormularioCadastro extends StatefulWidget {
  final String? codigoBarras;
  final String? fotoPath;
  final List<Map<String, dynamic>> categorias;
  final int? categoriaSelecionadaId;
  final DBHelper dbHelper;
  final VoidCallback onSalvo;

  const _FormularioCadastro({
    this.codigoBarras,
    this.fotoPath,
    required this.categorias,
    required this.categoriaSelecionadaId,
    required this.dbHelper,
    required this.onSalvo,
  });

  @override
  State<_FormularioCadastro> createState() => _FormularioCadastroState();
}

class _FormularioCadastroState extends State<_FormularioCadastro> {
  final _produtoController = TextEditingController();
  final _loteController = TextEditingController();
  DateTime? _dataVencimento;
  String? _fotoPath;
  int? _categoriaSelecionadaId;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _fotoPath = widget.fotoPath;
    _categoriaSelecionadaId = widget.categoriaSelecionadaId;
  }

  // Takes product photo using camera
  Future<void> _tirarFoto() async {
    final picker = ImagePicker();
    final imagem = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (imagem != null) setState(() => _fotoPath = imagem.path);
  }

  // Saves product to database and closes the form
  Future<void> _salvar() async {
    if (_produtoController.text.isEmpty ||
        _loteController.text.isEmpty ||
        _dataVencimento == null ||
        _categoriaSelecionadaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      await widget.dbHelper.inserir(Medicamento(
        categoriaId: _categoriaSelecionadaId!,
        produto: _produtoController.text,
        lote: _loteController.text,
        dataVencimento: DateFormat('dd/MM/yyyy').format(_dataVencimento!),
        criadoEm: DateTime.now(),
        codigoBarras: widget.codigoBarras,
        foto: _fotoPath,
      ));

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produto salvo!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSalvo();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Pushes form up when keyboard opens — fixes white screen bug
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Adicionar Produto',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // ===== PHOTO + BARCODE ROW =====
              Row(
                children: [
                  // Product photo thumbnail (tap to take photo)
                  GestureDetector(
                    onTap: _tirarFoto,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _fotoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(File(_fotoPath!),
                                  fit: BoxFit.cover),
                            )
                          : const Icon(Icons.camera_alt,
                              size: 36, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Shows scanned barcode value
                        if (widget.codigoBarras != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              widget.codigoBarras!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        // Product name input
                        TextField(
                          controller: _produtoController,
                          decoration: InputDecoration(
                            labelText: 'Nome do produto',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== CATEGORY DROPDOWN =====
              DropdownButtonFormField<int>(
                value: _categoriaSelecionadaId,
                decoration: InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: widget.categorias.map((cat) {
                  return DropdownMenuItem<int>(
                    value: cat['id'] as int,
                    child: Text(cat['nome'] as String),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _categoriaSelecionadaId = v),
              ),

              const SizedBox(height: 12),

              // ===== LOT NUMBER FIELD =====
              TextField(
                controller: _loteController,
                decoration: InputDecoration(
                  labelText: 'Lote',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.numbers),
                ),
              ),

              const SizedBox(height: 12),

              // ===== EXPIRY DATE PICKER =====
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dataVencimento = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.blue),
                      const SizedBox(width: 12),
                      Text(
                        _dataVencimento == null
                            ? 'Data de vencimento (ex.: DD-MM-AA)'
                            : DateFormat('dd/MM/yyyy')
                                .format(_dataVencimento!),
                        style: TextStyle(
                          color: _dataVencimento == null
                              ? Colors.grey
                              : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ===== SAVE BUTTON =====
              ElevatedButton(
                onPressed: _carregando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _carregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white)),
                      )
                    : const Text('Salvar Produto',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _produtoController.dispose();
    _loteController.dispose();
    super.dispose();
  }
}

// ===== BARCODE SCANNER PAGE =====
// Full screen camera view with targeting overlay
class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _lido = false; // prevents multiple scans

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Codigo'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Flashlight toggle button
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera feed
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_lido) return; // ignore if already scanned
              final barcode = capture.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _lido = true;
                Navigator.pop(context, barcode!.rawValue);
              }
            },
          ),

          // Dark overlay outside scanning area
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Blue border targeting frame
          Center(
            child: Container(
              width: 260,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Instruction label at bottom
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Aponte para o codigo de barras',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
