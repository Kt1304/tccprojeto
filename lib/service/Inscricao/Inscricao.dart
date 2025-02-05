import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:uuid/uuid.dart';

Future<String?> desinscreverUsuarioDeEvento(String inscricaoId) async {
  print("Tentando excluir a inscrição com ID: $inscricaoId");

  final inscricao = ParseObject('Inscricao')..objectId = inscricaoId;

  final response = await inscricao.delete();

  if (response.success) {
    return "Usuário removido do evento com sucesso!";
  } else {
    print("Erro ao remover a inscrição: ${response.error?.message}");
    return "Erro ao remover a inscrição.";
  }
}

Future<String?> inscreverUsuarioEmEvento(String userId, String eventId) async {
  ParseUser? currentUser = await ParseUser.currentUser() as ParseUser?;
  if (currentUser == null) {
    return "Usuário não autenticado";
  }
  
  final query = QueryBuilder<ParseObject>(ParseObject('Inscricao'))
    ..whereEqualTo('IdUsuario', userId)
    ..whereEqualTo('IdEvento', eventId);

  final existingInscription = await query.query();

  if (existingInscription.results != null && existingInscription.results!.isNotEmpty) {
    return "Usuário já está inscrito neste evento.";
  }

  final codigoInscricao = const Uuid().v4(); // Gera um UUID único

  final inscricao = ParseObject('Inscricao')
    ..set('IdUsuario', ParseObject('_User')..objectId = userId)
    ..set('IdEvento', ParseObject('Evento')..objectId = eventId)
    ..set('Data_inscricao', DateTime.now())
    ..set('CodigoInscricao', codigoInscricao); // Adicionando o código de inscrição

  final response = await inscricao.save();

  if (response.success) {
    return "Usuário cadastrado no evento com sucesso!";
  } else {
    print(response.error);
    return "Erro ao processar a inscrição.";
  }
}
