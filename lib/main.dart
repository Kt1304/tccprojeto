import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';  // Adicionar o import

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
  primary: Color.fromARGB(255, 0, 0, 0),
  secondary: Color(0xff03DAC6),
  surface: Color.fromARGB(255, 255, 255, 255),
  error: Color(0xffCF6679),
  onPrimary: Color.fromARGB(255, 255, 255, 255),
  onSecondary: Color.fromARGB(255, 255, 255, 255),
  onSurface: Color.fromARGB(255, 0, 0, 0),
  onError: Color.fromARGB(255, 255, 255, 255),
  brightness: Brightness.dark,
);

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inicio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: defaultColorScheme,
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(title: 'Inicio'),
    );
  }
}
