import 'package:flutter/material.dart';
import 'package:login_ui/service/Evento/Evento.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl
import 'package:login_ui/service/SairService.dart';

// Tela para Meus Eventos
class MeusEventos extends StatefulWidget {
  final String objectId;

  const MeusEventos({Key? key, required this.objectId}) : super(key: key);

  @override
  _MeusEventosState createState() => _MeusEventosState();
}

class _MeusEventosState extends State<MeusEventos> {
  late Future<List<Map<String, dynamic>>> inscricoesFuturas;

  @override
  void initState() {
    super.initState();
    inscricoesFuturas = fetchInscricoes();
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
              onPressed: () => logout(context), // Chamada para a função logout
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
          return const Center(
            child: Text('Você não está cadastrado em nenhum evento no momento.'),
          );
        } else {
          final eventos = snapshot.data!;
          return FutureBuilder<ParseUser?>(
            future: ParseUser.currentUser()
                .then((user) => user as ParseUser?), // Correção aqui
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(child: CircularProgressIndicator());
              }

              final userId = snapshot.data!.objectId!; // Obtém o ID do usuário

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

                  return buildEventCard(
                      evento, startDate, startTime, endDate, endTime, userId, context);
                },
              );
            },
          );
        }
      },
    ),
  );
}
}