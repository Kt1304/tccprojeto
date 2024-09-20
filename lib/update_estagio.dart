import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Future<void> updateEstagio(String objectId, String newName) async {
  final estagio = ParseObject('Estagio')..set('objectId', objectId);
  estagio.set('name', newName);

  final response = await estagio.save();

  if (response.success) {
    print('Estagio atualizado com sucesso!');
  } else {
    print('Erro ao atualizar estagio: ${response.error?.message}');
  }
}
