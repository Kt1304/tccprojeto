import 'package:flutter/material.dart';
import 'package:login_ui/Cadastro.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:email_validator/email_validator.dart';
import 'home_screen.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(title: 'Login'),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final QueryBuilder<ParseObject> queryUsuario =
        QueryBuilder<ParseObject>(ParseObject('Usuario'))
          ..whereEqualTo('Email', email)
          ..whereEqualTo('Senha', password);

    final ParseResponse response = await queryUsuario.query();

    setState(() {
      isLoading = false;
    });

    if (response.success &&
        response.results != null &&
        response.results!.isNotEmpty) {
      final ParseObject user = response.results!.first as ParseObject;
      final String objectId = user.objectId!;

     ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Login realizado com sucesso!')),
);

    // Navegação para HomeScreen, passando apenas o objectId
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(objectId: objectId),
      ),
    );
    } else {
      final QueryBuilder<ParseObject> queryEmail =
          QueryBuilder<ParseObject>(ParseObject('Usuario'))
            ..whereEqualTo('Email', email);
      final ParseResponse emailResponse = await queryEmail.query();

      if (emailResponse.success &&
          emailResponse.results != null &&
          emailResponse.results!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha incorreta')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email não encontrado')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
                maxWidth: 400), // Tamanho fixo do formulário
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text(
                  'Entrar',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
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
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, digite uma senha válida';
                          }
                          return null;
                        },
                        maxLines: 1,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Senha',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _login();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(
                              double.infinity, 50), // Botão largura cheia
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Entrar',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Cadastro()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        child: const Text(
                          'Cadastre-se',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
