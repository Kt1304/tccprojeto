import 'package:flutter/material.dart';
import 'package:login_ui/screens/login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Future<void> logout(BuildContext context) async {
  final ParseUser? currentUser = await ParseUser.currentUser() as ParseUser?;

  if (currentUser != null) {
    final ParseResponse response = await currentUser.logout();
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout realizado com sucesso!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginPage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no logout: ${response.error?.message}')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum usuário está logado.')),
    );
  }
}