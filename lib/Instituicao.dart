import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'nF4HPPvi88ti0PJcMHJtibww5d401SkgFrDqjqNO';
  const keyClientKey = 'jwFX5EyLpvDND8tKtIsMTyuyhRkb2L8T0hPuLZhz';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testar Inserção no Parse',
      home: TesteInsercao(),
    );
  }
}

class TesteInsercao extends StatefulWidget {
  const TesteInsercao({super.key});

  @override
  _TesteInsercaoState createState() => _TesteInsercaoState();
}

class _TesteInsercaoState extends State<TesteInsercao> {
  final TextEditingController _razaoSocialController = TextEditingController();
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _inserirInstituicao() async {
    final instituicao = ParseObject('Instituicao')
      ..set('RazaoSocial', _razaoSocialController.text)
      ..set('Cnpj', _cnpjController.text)
      ..set('Telefone', _telefoneController.text)
      ..set('Email', _emailController.text);

    final response = await instituicao.save();

    if (response.success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Instituição adicionada com sucesso!')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erro ao adicionar instituição: ${response.error?.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Instituição'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _razaoSocialController,
              decoration: const InputDecoration(labelText: 'Razão Social'),
            ),
            TextField(
              controller: _cnpjController,
              decoration: const InputDecoration(labelText: 'CNPJ'),
            ),
            TextField(
              controller: _telefoneController,
              decoration: const InputDecoration(labelText: 'Telefone'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _inserirInstituicao,
              child: const Text('Salvar Instituição'),
            ),
          ],
        ),
      ),
    );
  }
}
