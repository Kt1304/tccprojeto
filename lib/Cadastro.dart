import 'package:flutter/material.dart';
import 'package:login_ui/login_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:email_validator/email_validator.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

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
  final TextEditingController _confirmarSenha = TextEditingController();

  bool _obscurePassword = true;
  String? _fileName;
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _fileName = _pickedFile!.name;
      });
    }
  }

  Future<bool> _verificaDuplicidade(String campo, String valor) async {
    final QueryBuilder<ParseObject> query =
        QueryBuilder<ParseObject>(ParseObject('Usuario'))
          ..whereEqualTo(campo, valor);

    final ParseResponse response = await query.query();
    return response.results != null && response.results!.isNotEmpty;
  }

  Future<void> _saveFileToParse() async {
    if (_pickedFile != null) {
      // Cria um objeto ParseFile a partir do arquivo
      ParseFileBase parseFile = ParseFile(File(_pickedFile!.path!));

      // Salva o arquivo no Parse
      ParseResponse parseResponse = await parseFile.save();

      if (parseResponse.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo anexado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao anexar o arquivo!')),
        );
      }
    }
  }

  Future<void> _inserirUsuario() async {
    final String cpf = _cpfController.text;
    final String email = _emailController.text;

    bool cpfExiste = await _verificaDuplicidade('Cpf', cpf);
    bool emailExiste = await _verificaDuplicidade('Email', email);

    final String confirmarsenha = _confirmarSenha.text;
    final String senha = _senhaController.text;

    if (senha != confirmarsenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!')),
      );
      return;
    }

    if (cpfExiste || emailExiste) {
      String mensagemErro = '';
      if (cpfExiste) {
        mensagemErro += 'O CPF já está cadastrado.\n';
      }
      if (emailExiste) {
        mensagemErro += 'O e-mail já está cadastrado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro)),
      );
      return;
    }

    final ParseObject usuario = ParseObject('Usuario')
      ..set<String>('Nome', _nomeController.text)
      ..set<String>('Cpf', cpf)
      ..set<String>('Telefone', _telefoneController.text)
      ..set<String>('Email', email)
      ..set<String>('Cidade', _cidadeController.text)
      ..set<String>('Estado', _estadoController.text)
      ..set<String>('Senha', _senhaController.text);

    if (_pickedFile != null) {
      // Salva o arquivo como ParseFile
      ParseFileBase parseFile = ParseFile(File(_pickedFile!.path!));

      // Faz o upload do arquivo e aguarda o sucesso
      ParseResponse responseFile = await parseFile.save();

      if (responseFile.success) {
        // Salva o URL do arquivo no campo DocumentoValidacao
        usuario.set<String>('DocumentoValidacao', parseFile.url!);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar o arquivo no Parse!')),
        );
        return;
      }
    }

    final response = await usuario.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginPage(
                  title: 'pagina inicial',
                )),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar! Tente novamente')),
      );
    }
  }

  void _menuPrincipal() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.asset(
              'assets/imag/Sigga.png',
              height: 150,
              fit: BoxFit.contain,
            ),
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    )),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cpfController,
              keyboardType: TextInputType.number,
              inputFormatters: [cpfFormatter],
              decoration: InputDecoration(
                  labelText: 'CPF',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ))),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [telefoneFormatter],
              decoration: InputDecoration(
                labelText: 'Telefone',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    )),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 2,
                      ))),
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
              controller: _senhaController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    )),
                hintText: 'Digite sua senha',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmarSenha,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmar senha',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.white,
                      width: 2,
                    )),
                hintText: 'Confirme sua senha',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _inserirUsuario,
                child: const Text('Cadastrar-se'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white, width: 1),
                )),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                onPressed: _menuPrincipal,
                icon: const Icon(Icons.home),
                label: const Text('Retornar ao menu principal'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white, width: 1),
                )),
            const SizedBox(height: 10),
            ElevatedButton(
                onPressed: _pickFile, // Correção aqui!
                child: const Text('Anexar arquivo'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white, width: 1),
                ))
          ],
        ),
      ),
    );
  }
}
