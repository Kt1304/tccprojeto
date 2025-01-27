import 'package:flutter/material.dart';
import 'package:login_ui/excluir_inscricao.dart';
import 'package:login_ui/sair.dart';
import 'package:login_ui/gerar_certificados.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart'; // Importando o flutter_osm_plugin
import 'package:geolocator/geolocator.dart';

// Tela para Meus Eventos
class MeusEventos extends StatefulWidget {
  final String objectId;

  const MeusEventos({Key? key, required this.objectId}) : super(key: key);

  @override
  _MeusEventosState createState() => _MeusEventosState();
}

class _MeusEventosState extends State<MeusEventos> {
  late Future<List<Map<String, dynamic>>> inscricoesFuturas;

  Future<List<Map<String, dynamic>>> _fetchInscricoes() async {
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
        return response.results!.map((inscricao) {
          final evento = inscricao.get<ParseObject>('IdEvento');
          return {
            'objectId': inscricao?.objectId,
            'NomeEvento': evento?.get<String>('NomeEvento') ?? 'Sem Nome',
            'Descricao': evento?.get<String>('Descricao') ?? 'Sem descrição',
            'DataInicio': evento?.get<DateTime>('DataInicio') ?? DateTime.now(),
            'DataFim': evento?.get<DateTime>('DataFim') ?? DateTime.now(),
            'Location': {
              'latitude':
                  evento?.get<ParseGeoPoint>('Location')?.latitude ?? 0.0,
              'longitude':
                  evento?.get<ParseGeoPoint>('Location')?.longitude ?? 0.0,
            },
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

  @override
  void initState() {
    super.initState();
    inscricoesFuturas = _fetchInscricoes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Meus Eventos'),
        actions: [
          Row(
            children: [
              const Text('Sair'),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    logout(context), // Chamada para a função logout
              ),
            ],
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: inscricoesFuturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Erro ao carregar eventos:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma inscrição encontrada.'));
          } else {
            final eventos = snapshot.data!;
            return FutureBuilder<ParseUser?>(
              future: ParseUser.currentUser()
                  .then((user) => user as ParseUser?), // Correção aqui
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return Center(child: CircularProgressIndicator());
                }

                final userId =
                    snapshot.data!.objectId!; // Obtém o ID do usuário

                return ListView.builder(
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];

                    final startDate = DateFormat('dd/MM/yyyy')
                        .format(evento['DataInicio'] as DateTime);
                    final startTime = DateFormat('HH:mm')
                        .format(evento['DataInicio'] as DateTime);
                    final endDate = DateFormat('dd/MM/yyyy')
                        .format(evento['DataFim'] as DateTime);
                    final endTime = DateFormat('HH:mm')
                        .format(evento['DataFim'] as DateTime);

                    return _buildEventCard(
                        evento, startDate, startTime, endDate, endTime, userId);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
Widget _buildEventCard(Map<String, dynamic> evento, String startDate,
    String startTime, String endDate, String endTime, String userId) {
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

                GeoPoint? position = await _determinePosition();
                if (position != null) {
                  final inscricaoId = evento['objectId']; // A chave correta do evento
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

                  if (await _isLocationClose(position.latitude,
                      position.longitude, eventLat, eventLong)) {
                    print("Você está no evento! Pode validar o certificado.");
                  } else {
                    print("Você não está no evento.");
                    print(
                        'Posição do usuário: ${position.latitude}, ${position.longitude}');
                    print('Posição do evento: $eventLat, $eventLong');
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
          PopupMenuButton<String>(
            icon: Icon(Icons.menu_rounded), // Ícone sanduíche
            onSelected: (String result) {
              if (result == 'certificado') {
                gerarCertificadoAluno(userId, evento['idEvento'], context);
                print('Gerar Certificado');
                // Chamar função para gerar certificado
              } else if (result == 'editar') {
                print('Editar Evento');
                // Navegar para tela de edição do evento
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'certificado',
                child: Text('Gerar Certificado'),
              ),
              PopupMenuItem<String>(
                value: 'editar',
                child: Text('Editar Evento'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Future<GeoPoint?> _determinePosition() async {
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
        desiredAccuracy: LocationAccuracy.high,
      );

      return GeoPoint(
          latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      print("Erro ao obter localização: $e");
      return null;
    }
  }

  Future<bool> _isLocationClose(double userLat, double userLong,
      double eventLat, double eventLong) async {
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
}
