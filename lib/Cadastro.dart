import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Importando o file_picker
import 'dart:io'; // Importação para File
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'nF4HPPvi88ti0PJcMHJtibww5d401SkgFrDqjqNO';
  const keyClientKey = 'jwFX5EyLpvDND8tKtIsMTyuyhRkb2L8T0hPuLZhz';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cadastro',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Cadastro(),
    );
  }
}

final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
final telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  _CadastroState createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _telefoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  Future<void> _inserirUsuario() async {
    final ParseObject usuario = ParseObject('Usuario')
      ..set<String>('Nome', _nomeController.text)
      ..set<String>('Cpf', _cpfController.text)
      ..set<String>('Telefone', _telefoneController.text)
      ..set<String>('Email', _emailController.text)
      ..set<String>('Cidade', _cidadeController.text)
      ..set<String>('Estado', _estadoController.text)
      ..set<String>('Senha', _senhaController.text);

    final response = await usuario.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar! Tente novamente')),
      );
    }
  }

  void _menuPrincipal() {
    Navigator.pop(context);
    // Retorna para a página anterior (menu principal)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cadastre-se"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(
                  labelText: 'Nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [cpfFormatter],
              decoration: const InputDecoration(
                  labelText: 'CPF', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [telefoneFormatter],
              decoration: const InputDecoration(
                  labelText: 'Telefone', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'E-mail', border: OutlineInputBorder()),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira seu e-mail';
                }
                if (!EmailValidator.validate(value)) {
                  return 'Por favor, insira um e-mail válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cidadeController,
              decoration: const InputDecoration(
                  labelText: 'Cidade', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _estadoController,
              decoration: const InputDecoration(
                  labelText: 'Estado', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _senhaController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                  hintText: 'Digite sua senha'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _inserirUsuario,
              child: const Text('Cadastrar-se'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _menuPrincipal,
              icon: const Icon(Icons.home),
              label: const Text('Retornar ao menu principal'),
            ),
          ],
        ),
      ),
    );
  }
}
