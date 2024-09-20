import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

Future<void> readEstagio(String objectId) async {
  final query = QueryBuilder(ParseObject('Estagio'))
    ..whereEqualTo('objectId', objectId);

  final response = await query.query();

  if (response.success && response.results != null) {
    final estagio = response.results!.first as ParseObject;
    print('Estagio encontrado: ${estagio.toString()}');
  } else {
    print('Erro ao ler estagio: ${response.error?.message}');
  }
}
