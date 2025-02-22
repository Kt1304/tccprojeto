import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';  // Adicionar o import

// Adicionar o import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializando o Parse
  const keyApplicationId = 'nF4HPPvi88ti0PJcMHJtibww5d401SkgFrDqjqNO';
  const keyClientKey = 'jwFX5EyLpvDND8tKtIsMTyuyhRkb2L8T0hPuLZhz';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(const MyApp());
}

ColorScheme defaultColorScheme = const ColorScheme(
  primary: Color.fromARGB(255, 252, 247, 248),
  secondary: Color.fromARGB(255, 0, 0, 0),
  surface: Color.fromARGB(255, 19, 42, 72),
  error: Color.fromARGB(255, 255, 255, 255),
  onPrimary: Color.fromARGB(255, 0, 0, 0),
  onSecondary: Color.fromARGB(255, 0, 0, 0),
  onSurface: Color.fromARGB(255, 241, 241, 241),
  onError: Color.fromARGB(255, 255, 255, 255),
  brightness: Brightness.light,
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: defaultColorScheme,
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
