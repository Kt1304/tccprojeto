import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:login_ui/screens/principal_home_screen.dart';

Future<void> login(BuildContext context, TextEditingController emailController, TextEditingController passwordController, Function(bool) setLoading) async {
  setLoading(true);

  final email = emailController.text.trim();
  final password = passwordController.text.trim();

  final ParseUser user = ParseUser(email, password, null);
  final ParseResponse response = await user.login();

  setLoading(false);

  if (response.success && response.result != null) {
    final ParseUser loggedInUser = response.result;
    final String objectId = loggedInUser.objectId!;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login realizado com sucesso!')),
    );

    Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => HomeScreen(objectId: objectId),
  ),
    );
  } else {
    if (response.error?.code == 101) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Senha incorreta')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.error?.message ?? 'Erro desconhecido')),
      );
    }
  }
}
