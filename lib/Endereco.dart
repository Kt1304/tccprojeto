import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Corrigir a importação para 'dart:io'

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
      title: 'Testar Inserção de Endereço',
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
  final TextEditingController _estadoController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _cepController = TextEditingController();
  final TextEditingController _bairroController = TextEditingController();
  final TextEditingController _ruaController = TextEditingController();
  final TextEditingController _idInstituicaoController =
      TextEditingController();
  File? _selectedFile;

  // Método para selecionar o arquivo PDF
  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  // Método para fazer upload do arquivo e salvar o endereço no Parse
  Future<void> _inserirEndereco() async {
    // Verifique se o arquivo foi selecionado
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione um arquivo PDF')),
      );
      return;
    }

    // Faça o upload do arquivo PDF
    final parseFile = ParseFile(_selectedFile!);
    final fileResponse = await parseFile.save();

    if (!fileResponse.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Erro ao fazer upload do arquivo: ${fileResponse.error?.message}')),
      );
      return;
    }

    // Crie o ponteiro para a instituição
    final instituicaoPointer = ParseObject('Instituicao')
      ..set('objectId', _idInstituicaoController.text);

    // Crie o objeto Endereco com o arquivo PDF
    final endereco = ParseObject('Endereco')
      ..set('Estado', _estadoController.text)
      ..set('Cidade', _cidadeController.text)
      ..set('Cep', _cepController.text)
      ..set('Bairro', _bairroController.text)
      ..set('Rua', _ruaController.text)
      ..set('IdInstituicao', instituicaoPointer) // Use o ponteiro aqui
      ..set('DocumentoPDF', parseFile); // Adiciona o arquivo PDF ao campo

    // Salve o endereço com o arquivo PDF
    final response = await endereco.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Endereço e PDF adicionados com sucesso!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erro ao adicionar endereço: ${response.error?.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Endereço'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _estadoController,
              decoration: const InputDecoration(labelText: 'Estado'),
            ),
            TextField(
              controller: _cidadeController,
              decoration: const InputDecoration(labelText: 'Cidade'),
            ),
            TextField(
              controller: _cepController,
              decoration: const InputDecoration(labelText: 'CEP'),
            ),
            TextField(
              controller: _bairroController,
              decoration: const InputDecoration(labelText: 'Bairro'),
            ),
            TextField(
              controller: _ruaController,
              decoration: const InputDecoration(labelText: 'Rua'),
            ),
            TextField(
              controller: _idInstituicaoController,
              decoration: const InputDecoration(labelText: 'ID da Instituição'),
            ),
            const SizedBox(
              height: 25.0,
            ),
            ElevatedButton(
              onPressed: pickFile,
              child: Padding(
                padding: EdgeInsets.all(8.1),
                child: const Text('Selecione seu R.A ou SIAPE'),
              ),
            ),
            ElevatedButton(
              onPressed: _inserirEndereco,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: const Text('Salvar Endereço e PDF'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
