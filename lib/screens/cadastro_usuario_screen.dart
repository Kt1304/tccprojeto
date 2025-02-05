import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:login_ui/service/Perfil/_User.dart';

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

  final CadastroService _cadastroService = CadastroService();

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
                onPressed: () async {
                  await _cadastroService.inserirUsuario(
                    nome: _nomeController.text,
                    cpf: _cpfController.text,
                    telefone: _telefoneController.text,
                    email: _emailController.text,
                    cidade: _cidadeController.text,
                    estado: _estadoController.text,
                    senha: _senhaController.text,
                    confirmarSenha: _confirmarSenha.text,
                    context: context,
                  );
                },
                child: const Text('Cadastrar-se'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1),
                )),
            const SizedBox(height: 10),
            ElevatedButton.icon(
                onPressed: _menuPrincipal,
                icon: const Icon(Icons.home),
                label: const Text('Retornar ao menu principal'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1),
                )),
          ],
        ),
      ),
    );
  }
}