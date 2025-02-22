import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:login_ui/service/Inscricao/Inscricao.dart';
import 'package:login_ui/service/Certificado/Certificado.dart';

Future<List<Map<String, dynamic>>> fetchInscricoes() async {
  try {
    final user = await ParseUser.currentUser() as ParseUser?;

    if (user == null) {
      throw Exception('Usuário não está autenticado');
    }

    // Consulta para pegar todas as inscrições do usuário
    final query = QueryBuilder<ParseObject>(ParseObject('Inscricao'))
      ..whereEqualTo(
          'IdUsuario',
          ParseObject('_User')
            ..objectId = user
                .objectId) // Garantindo que estamos buscando as inscrições do usuário
      ..includeObject(['IdEvento']); // Inclui os detalhes do evento associado

    final response = await query.query();

    if (response.success && response.results != null) {
      final now = DateTime.now();
      return response.results!.where((inscricao) {
        final evento = inscricao.get<ParseObject>('IdEvento');
        final dataFim = evento?.get<DateTime>('DataFim') ?? DateTime.now();
        return dataFim.isAfter(now);

        // Filtra os eventos que ainda não passaram da DataFim
      }).map((inscricao) {
        final evento = inscricao.get<ParseObject>('IdEvento');
        return {
          'objectId': inscricao.objectId,
          'NomeEvento': evento?.get<String>('NomeEvento') ?? 'Sem Nome',
          'Descricao': evento?.get<String>('Descricao') ?? 'Sem descrição',
          'DataInicio': evento?.get<DateTime>('DataInicio') ?? DateTime.now(),
          'DataFim': evento?.get<DateTime>('DataFim') ?? DateTime.now(),
          'Location': {
            'latitude': evento?.get<ParseGeoPoint>('Location')?.latitude ?? 0.0,
            'longitude':
                evento?.get<ParseGeoPoint>('Location')?.longitude ?? 0.0,
          },
          'CertificadoValidado': inscricao.get<bool>('CertificadoValidado') ??
              false, // Verifica se o certificado já foi validado
        };
      }).toList();
    } else {
      throw Exception(
          'Erro ao carregar inscrições: ${response.error?.message ?? 'Desconhecido'}');
    }
  } catch (e) {
    print("Erro ao carregar as inscrições: $e");
    rethrow;
  }
}

Widget buildEventCard(
    Map<String, dynamic> evento,
    String startDate,
    String startTime,
    String endDate,
    String endTime,
    String userId,
    BuildContext context) {
  return Card(
    elevation: 4,
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(Icons.event, color: Colors.green[700]),
      title: Text(
        evento['NomeEvento'],
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        '${evento['Descricao']}\n'
        'Data Início: $startDate às $startTime\n'
        'Data Fim: $endDate às $endTime',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone para o certificado
          IconButton(
            icon: Icon(Icons.assignment_turned_in, color: Colors.blue),
            onPressed: () async {
              try {
                print("Evento recebido: $evento");

                // Verificar se o certificado já foi validado
                if (evento['CertificadoValidado'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Certificado já validado.'),
                    ),
                  );
                  return; // Retorna caso o certificado já tenha sido validado
                }

                GeoPoint? position = await determinePosition();
                if (position != null) {
                  final inscricaoId =
                      evento['objectId']; // A chave correta do evento
                  print("Id da inscrição: $inscricaoId");

                  if (inscricaoId == null || inscricaoId.isEmpty) {
                    print("Erro: Id da inscrição não encontrado.");
                    return; // Retorna caso não encontre o id da inscrição
                  }

                  // Buscar a inscrição usando o objectId da inscrição
                  ParseObject inscricaoObj = ParseObject('Inscricao')
                    ..objectId = inscricaoId;
                  try {
                    inscricaoObj = await inscricaoObj.fetch();
                  } catch (e) {
                    print("Erro ao buscar inscrição: $e");
                    return; // Retorna caso ocorra erro na busca da inscrição
                  }

                  // Recuperar o ponteiro IdEvento da inscrição
                  final eventoPointer = inscricaoObj.get('IdEvento');
                  if (eventoPointer == null) {
                    print("Erro: IdEvento não encontrado na inscrição.");
                    return; // Retorna caso não encontre o evento
                  }

                  // O eventoPointer já é um ParseObject com o ID do evento
                  final eventoId = eventoPointer.objectId;
                  if (eventoId == null || eventoId.isEmpty) {
                    print("Erro: ID do evento não encontrado.");
                    return; // Retorna caso não encontre o ID do evento
                  }

                  // Buscar o evento usando o IdEvento (ponteiro)
                  ParseObject eventoObj = ParseObject('Evento')
                    ..objectId = eventoId;
                  try {
                    eventoObj = await eventoObj.fetch();
                  } catch (e) {
                    print("Erro ao buscar evento: $e");
                    return; // Retorna caso não consiga buscar o evento
                  }

                  // Recuperar a localização do evento como ParseGeoPoint
                  ParseGeoPoint? location =
                      eventoObj.get<ParseGeoPoint>('Location');
                  if (location == null) {
                    print("Erro: Localização do evento não definida.");
                    return; // Retorna caso não encontre a localização
                  }

                  // Converta ParseGeoPoint para coordenadas
                  final eventLat = location.latitude;
                  final eventLong = location.longitude;

                  if (eventLat == 0.0 && eventLong == 0.0) {
                    print("Erro: Coordenadas do evento não estão definidas.");
                    return; // Retorna caso as coordenadas estejam erradas
                  }

                  // Verificar se a data atual está dentro do intervalo do evento
                  final now = DateTime.now();
                  final startDate = eventoObj.get<DateTime>('DataInicio');
                  final endDate = eventoObj.get<DateTime>('DataFim');

                  if (startDate == null || endDate == null) {
                    print("Erro: Datas do evento não estão definidas.");
                    return; // Retorna caso as datas não estejam definidas
                  }

                  if (now.isBefore(startDate) || now.isAfter(endDate)) {
                    print("Fora do período do evento.");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fora do período do evento.'),
                      ),
                    );
                    return; // Retorna caso a data atual esteja fora do intervalo do evento
                  }

                  if (await isLocationClose(position.latitude,
                      position.longitude, eventLat, eventLong)) {
                    print("Você está no evento! Pode validar o certificado.");
                    // Exibir mensagem de sucesso
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Você está no evento! Pode validar o certificado.'),
                      ),
                    );
                    // Gerar o PDF do certificado
                    await PdfService.gerarESalvarPdfCertificado(
                      eventoObj.get<String>('NomeEvento') ??
                          'Evento Desconhecido',
                      eventoObj.get<String>('Descricao') ?? 'Sem descrição',
                      inscricaoId, // ID da inscrição (evento['objectId'])
                    );

                    // Marcar o certificado como validado
                    inscricaoObj.set('CertificadoValidado', true);
                    await inscricaoObj.save();
                  } else {
                    print("Você não está no evento.");
                    print(
                        'Posição do usuário: ${position.latitude}, ${position.longitude}');
                    print('Posição do evento: $eventLat, $eventLong');
                    // Exibir mensagem de erro
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Você não está no evento ou no horário correto.'),
                      ),
                    );
                  }
                } else {
                  print("Erro ao obter a localização do usuário.");
                }
              } catch (e) {
                print("Erro geral: $e");
              }
            },
          ),
          // Ícone para deletar
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final inscricaoId = evento['objectId'];
              if (inscricaoId == null) {
                print("Erro: Id não encontrado");
                return;
              }

              String? finalUserId = userId;
              if (finalUserId == null) {
                ParseUser? currentUser =
                    await ParseUser.currentUser() as ParseUser?;
                finalUserId = currentUser?.objectId;
              }

              if (finalUserId != null) {
                desinscreverUsuarioDeEvento(inscricaoId);
              } else {
                print("Erro: Usuário ou Evento inválido.");
                print("evento: $inscricaoId");
              }
            },
          ),
        ],
      ),
    ),
  );
}

Future<GeoPoint?> determinePosition() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização não habilitado.');
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw Exception('Permissão para acessar localização negada.');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    return GeoPoint(latitude: position.latitude, longitude: position.longitude);
  } catch (e) {
    print("Erro ao obter localização: $e");
    return null;
  }
}

Future<bool> isLocationClose(
    double userLat, double userLong, double eventLat, double eventLong) async {
  try {
    final distance = await distance2point(
      GeoPoint(latitude: userLat, longitude: userLong),
      GeoPoint(latitude: eventLat, longitude: eventLong),
    );
    return distance <= 200; // 200 metros
  } catch (e) {
    print("Erro ao calcular distância: $e");
    return false;
  }
}

class EventoHomeService {
  // Função para buscar eventos no banco de dados
  static Future<List<Map<String, dynamic>>> fetchEventos() async {
    final query = QueryBuilder(ParseObject('Evento'))
      ..orderByAscending('DataInicio');

    final response = await query.query();

    if (response.success && response.results != null) {
      List<Map<String, dynamic>> eventos = [];
      for (var evento in response.results!) {
        eventos.add({
          'objectId': evento.objectId,
          'NomeEvento': evento.get<String>('NomeEvento') ?? 'Sem Nome',
          'Descricao': evento.get<String>('Descricao') ?? 'Sem descrição',
          'DataInicio': evento.get<DateTime>('DataInicio') ?? DateTime.now(),
          'DataFim': evento.get<DateTime>('DataFim') ?? DateTime.now(),
          'Vagas': evento.get<int>('Vagas') ?? 0,
          'Lat': evento.get<double>('Lat') ?? 0.0,
          'Long': evento.get<double>('Long') ?? 0.0,
          'idUsuario': evento.get<String>('idUsuario') ?? '',
          'idInstituicao': evento.get<String>('idInstituicao') ?? '',
        });
      }
      return eventos;
    } else {
      throw Exception('Erro ao carregar eventos');
    }
  }

  static Future<String?> inscreverUsuarioEmEvento(
      String userId, String eventId) async {
    // Verifica se o userId e eventId não estão vazios
    if (userId.isEmpty || eventId.isEmpty) {
      return "Erro: ID do usuário ou do evento não pode ser vazio.";
    }

    // Verifica se o usuário já está inscrito no evento
    final query = QueryBuilder<ParseObject>(ParseObject('Inscricao'))
      ..whereEqualTo('IdUsuario', ParseObject('_User')..objectId = userId)
      ..whereEqualTo('IdEvento', ParseObject('Evento')..objectId = eventId);

    final response = await query.query();

    if (response.success &&
        response.results != null &&
        response.results!.isNotEmpty) {
      return "Você já está inscrito neste evento.";
    }

    // Cria um Pointer para o usuário
    final userPointer = ParseObject('_User')..objectId = userId;

    // Cria um Pointer para o evento
    final eventPointer = ParseObject('Evento')..objectId = eventId;

    // Cria a inscrição com os Pointers corretos e a data de inscrição
    final inscricao = ParseObject('Inscricao')
      ..set('IdUsuario', userPointer) // Usa o Pointer para o usuário
      ..set('IdEvento', eventPointer) // Usa o Pointer para o evento
      ..set('Data_inscricao', DateTime.now()); // Adiciona a data de inscrição

    final saveResponse = await inscricao.save();

    if (saveResponse.success) {
      return "Inscrição realizada com sucesso!";
    } else {
      return "Erro ao se inscrever no evento: ${saveResponse.error?.message}";
    }
  }
}

class EventoService {
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Serviço de localização está desativado.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Permissão de localização negada permanentemente. Não é possível continuar.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);
  }

  Future<void> cadastrarEvento({
    required String nome,
    required String descricao,
    required DateTime dataInicio,
    required DateTime dataFim,
    required int vagas,
    required Position position,
    required String idUsuario,
    required String idInstituicao,
  }) async {
    var instituicaoPointer = ParseObject('Instituicao')
      ..objectId = idInstituicao;

    var evento = ParseObject('Evento')
      ..set('NomeEvento', nome)
      ..set('Descricao', descricao)
      ..set('DataInicio', dataInicio)
      ..set('DataFim', dataFim)
      ..set('Vagas', vagas)
      ..set(
          'Location',
          ParseGeoPoint(
              latitude: position.latitude, longitude: position.longitude))
      ..set('IdUsuario', ParseUser.forQuery()..objectId = idUsuario)
      ..set('IdInstituicao', instituicaoPointer);

    var response = await evento.save();
    if (!response.success) {
      throw Exception(response.error?.message ?? 'Erro desconhecido');
    }
  }
}



class EventoAlterarService {
  static Future<List<ParseObject>> carregarEventos(String objectId) async {
    try {
      QueryBuilder<ParseObject> queryEventos = QueryBuilder<ParseObject>(
          ParseObject('Evento'))
        ..whereEqualTo('IdUsuario', ParseObject('_User')..objectId = objectId)
        ..whereGreaterThan('DataFim', DateTime.now());
        
      final ParseResponse response = await queryEventos.query();

      if (response.success && response.results != null) {
        return response.results as List<ParseObject>;
      } else {
        throw Exception("Erro ao carregar eventos.");
      }
    } catch (e) {
      throw Exception("Erro inesperado: $e");
    }
  }

  static Future<void> excluirEvento(ParseObject evento) async {
    try {
      final ParseResponse response = await evento.delete();
      if (!response.success) {
        throw Exception("Erro ao excluir evento.");
      }
    } catch (e) {
      throw Exception("Erro inesperado: $e");
    }
  }

  static Future<void> salvarAlteracoes(
    ParseObject evento,
    String nome,
  String descricao,
  String dataInicio,
  String dataFim,
  String vagas,
  ) async {
    try {
      evento.set<String>('NomeEvento', nome);
      evento.set<String>('Descricao', descricao);
      evento.set<DateTime>('DataInicio', DateTime.parse(dataInicio));
      evento.set<DateTime>('DataFim', DateTime.parse(dataFim));
      evento.set<int>('Vagas', int.parse(vagas));

      final ParseResponse response = await evento.save();

      if (!response.success) {
        throw Exception("Erro ao atualizar o evento.");
      }
    } catch (e) {
      throw Exception("Erro inesperado: $e");
    }
  }
}
