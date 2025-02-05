import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl
import 'package:login_ui/service/Evento/Evento.dart';
import 'package:login_ui/service/SairService.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

// Tela de conteúdo da Home (Eventos)
class HomeContent extends StatefulWidget {
  final String objectId;
  const HomeContent({Key? key, required this.objectId}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Map<String, dynamic>>> eventosFuturos;

  @override
  void initState() {
    super.initState();
    eventosFuturos = EventoHomeService.fetchEventos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Eventos'),
        actions: [
          Row(
            children: [
              const Text('Sair'),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => logout(context), // Chamada para a função logout
              ),
            ],
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: eventosFuturos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum evento encontrado.'));
          } else {
            final eventos = snapshot.data!
                .where((evento) => evento['DataInicio'].isAfter(DateTime.now()))
                .toList();

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                itemCount: eventos.length,
                itemBuilder: (context, index) {
                  final evento = eventos[index];

                  // Formatação da data
                  final startDate =
                      DateFormat('dd/MM/yyyy').format(evento['DataInicio']);
                  final startTime =
                      DateFormat('HH:mm').format(evento['DataInicio']);
                  final endDate =
                      DateFormat('dd/MM/yyyy').format(evento['DataFim']);
                  final endTime = DateFormat('HH:mm').format(evento['DataFim']);

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Icon(Icons.event, color: Colors.green[700]),
                      title: Text(
                        evento['NomeEvento'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${evento['Descricao']}\n'
                        'Data Início: $startDate às $startTime\n'
                        'Data Fim: $endDate às $endTime\n'
                        'Vagas: ${evento['Vagas']} vagas',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          print("Dados do evento: $evento");

                          // Correção do erro de digitação no acesso ao objectId
                          String? eventId = evento.containsKey('objectId')
                              ? evento['objectId']
                              : null;

                          if (eventId == null || eventId.isEmpty) {
                            print("Erro: ID do evento não encontrado.");
                            return; // Evita continuar se não houver ID do evento
                          }

                          // Obtendo o usuário autenticado
                          ParseUser? currentUser =
                              await ParseUser.currentUser() as ParseUser?;
                          if (currentUser != null) {
                            String userId = currentUser.objectId ?? "";

                            print("ID do usuário: $userId");
                            print("ID do evento: $eventId");

                            if (eventId.isNotEmpty && userId.isNotEmpty) {
                              String? resultado =
                                  await EventoHomeService.inscreverUsuarioEmEvento(
                                      userId, eventId);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        resultado ?? "Erro ao se inscrever")),
                              );
                            } else {
                              print("Erro: ID do usuário ou do evento vazio.");
                            }
                          } else {
                            print("Usuário não autenticado.");
                          }
                        },
                        child: const Text('Inscrever-se'),
                      ),
                      onTap: () {
                        // Lógica para abrir a página de detalhes do evento
                      },
                    ),
                  );
                },
              ),
            );
          }
        },
      ),
    );
  }
}