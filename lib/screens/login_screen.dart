import 'package:flutter/material.dart';
import 'package:login_ui/screens/cadastro_usuario_screen.dart';
import 'package:login_ui/screens/recuperar_senha_screen.dart';
import 'package:email_validator/email_validator.dart';
import 'package:login_ui/service/LoginService.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  void setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset('assets/imag/Sigga.png',
                    width: 350, height: 350, fit: BoxFit.contain),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildEmailField(),
                      const SizedBox(height: 15),
                      _buildPasswordField(),
                      const SizedBox(height: 15),
                      _buildLoginButton(),
                      const SizedBox(height: 15),
                      _buildRegisterButton(),
                      _buildForgotPasswordButton(),
                      const SizedBox(height: 15)
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      validator: (value) => EmailValidator.validate(value!)
          ? null
          : "Por favor, digite um email válido",
      maxLines: 1,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: const Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, digite uma senha válida';
        }
        return null;
      },
      maxLines: 1,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Senha',
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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () {
              if (_formKey.currentState!.validate()) {
                login(context, _emailController, _passwordController, setLoading);
              }
            },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text(
              'Entrar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const Cadastro()),
        );
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
      ),
      child: const Text(
        'Cadastre-se',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RecuperarSenha(),
          ),
        );
      },
      child: const Text(
        'Esqueceu a senha?',
        style: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
}
