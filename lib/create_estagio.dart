import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Future<void> createEstagio(String name, String cpf, String instituicao) async {
  final estagio = ParseObject('Estagio')
    ..set('name', name)
    ..set('cpf', cpf)
    ..set('Instituicao', instituicao);

  final response = await estagio.save();

  if (response.success) {
    print('Estagio criado com sucesso! ID: ${response.result['objectId']}');
  } else {
    print('Erro ao criar estagio: ${response.error?.message}');
  }
}
