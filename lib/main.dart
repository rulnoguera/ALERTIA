import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';

void main() {
  runApp(const AlertiaApp());
}

class AlertiaApp extends StatelessWidget {
  const AlertiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alertia',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F3A5F)),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}

class AllergenItem {
  final String name;
  final String tagOff;
  bool isSelected;

  AllergenItem({required this.name, required this.tagOff, this.isSelected = false});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _barcodeController = TextEditingController(text: "3017620422003");
  bool _isLoading = false;

  final List<AllergenItem> _leftColumn = [
    AllergenItem(name: "Proteína de la leche", tagOff: "en:milk"),
    AllergenItem(name: "Gluten", tagOff: "en:gluten"),
    AllergenItem(name: "Huevo", tagOff: "en:eggs"),
    AllergenItem(name: "Soja", tagOff: "en:soybeans"),
    AllergenItem(name: "Cacahuete", tagOff: "en:peanuts"),
    AllergenItem(name: "Pescado", tagOff: "en:fish"),
    AllergenItem(name: "Crustáceos", tagOff: "en:crustaceans"),
    AllergenItem(name: "Moluscos", tagOff: "en:molluscs"),
  ];

  final List<AllergenItem> _rightColumn = [
    AllergenItem(name: "Lactosa", tagOff: "special:lactose"),
    AllergenItem(name: "Fructosa", tagOff: "special:fructose"),
    AllergenItem(name: "Frutos de cáscara", tagOff: "en:nuts"),
    AllergenItem(name: "Sésamo", tagOff: "en:sesame-seeds"),
    AllergenItem(name: "Mostaza", tagOff: "en:mustard"),
    AllergenItem(name: "Apio", tagOff: "en:celery"),
    AllergenItem(name: "Altramuz", tagOff: "en:lupin"),
    AllergenItem(name: "Sulfitos", tagOff: "en:sulphites"),
  ];

  Future<void> _openCameraScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null && scannedCode.isNotEmpty) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
      _analyzeProduct();
    }
  }

  Future<void> _analyzeProduct() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v3/product/$barcode?fields=code,product_name,ingredients_text,allergens_tags,traces_tags',
      );
      final response = await http.get(url, headers: {
        'User-Agent': 'Alertia/0.1 (prototype)',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final product = data['product'] ?? {};

        final selectedAllergens = [
          ..._leftColumn.where((item) => item.isSelected),
          ..._rightColumn.where((item) => item.isSelected),
        ];

        final allergensTags = List<String>.from(product['allergens_tags'] ?? []);
        
        List<String> detected = [];
        for (var item in selectedAllergens) {
          if (allergensTags.contains(item.tagOff)) {
            detected.add(item.name);
          }
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResultScreen(
              productName: product['product_name'] ?? 'Producto sin nombre',
              detectedAllergens: detected,
              allergensTags: allergensTags,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al consultar Open Food Facts: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1F3A5F),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F3A5F))),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn(_leftColumn)),
                Expanded(child: _buildColumn(_rightColumn)),
              ],
            ),
            const SizedBox(height: 25),
            const Text('Producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F3A5F))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Introduce código o escanea',
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF1F3A5F),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
                  onPressed: _openCameraScanner,
                  tooltip: 'Escanear con la cámara',
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E7CC3)),
                onPressed: _isLoading ? null : _analyzeProduct,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Analizar producto', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(List<AllergenItem> items) {
    return Column(
      children: items.map((item) {
        return CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(item.name, style: const TextStyle(fontSize: 13)),
          value: item.isSelected,
          onChanged: (val) => setState(() => item.isSelected = val ?? false),
        );
      }).toList(),
    );
  }
}

class BarcodeScannerScreen extends StatelessWidget {
  const BarcodeScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear código de barras', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F3A5F),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break;
            }
          }
        },
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final String productName;
  final List<String> detectedAllergens;
  final List<String> allergensTags;

  const ResultScreen({
    super.key,
    required this.productName,
    required this.detectedAllergens,
    required this.allergensTags,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasAlert = detectedAllergens.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1F3A5F),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(productName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasAlert ? const Color(0xFFE53935) : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                hasAlert ? 'ALERTA: ${detectedAllergens.join(" · ")}' : 'INFORMACIÓN INSUFICIENTE',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasAlert ? Colors.white : const Color(0xFF8A6500),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              hasAlert
                  ? 'Se han detectado alérgenos de tu perfil: ${detectedAllergens.join(" · ")}'
                  : 'No hay información suficiente para evaluar este producto.',
              style: const TextStyle(fontSize: 15),
            ),
            const Spacer(),
            const Text('Fuente: Open Food Facts', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            const Text('No consideres este producto seguro hasta verificar su etiqueta.',
                style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}