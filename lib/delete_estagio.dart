import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Future<void> deleteEstagio(String objectId) async {
  final estagio = ParseObject('Estagio')..set('objectId', objectId);

  final response = await estagio.delete();

  if (response.success) {
    print('Estagio deletado com sucesso!');
  } else {
    print('Erro ao deletar estagio: ${response.error?.message}');
  }
}
