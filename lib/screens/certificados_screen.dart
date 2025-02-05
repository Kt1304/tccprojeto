import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:login_ui/service/SairService.dart';
import 'package:login_ui/service/Certificado/Certificado.dart';

class CertificadosScreen extends StatelessWidget {
  final String userObjectId;

  const CertificadosScreen({Key? key, required this.userObjectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final certificadosService = CertificadosService(userObjectId: userObjectId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificados'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),
      body: FutureBuilder<List<ParseObject>>(
        future: certificadosService.buscarCertificados(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error.toString()}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum certificado encontrado'));
          }

          final certificados = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: certificados.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final certificado = certificados[index];
              final dynamic arquivo = certificado.get('arquivo');
              final String? urlArquivo =
                  (arquivo is ParseFile || arquivo is ParseWebFile) ? arquivo.url : null;
              final evento = certificado.get<ParseObject>('evento');
              final nomeEvento = evento?.get<String>('NomeEvento') ?? 'Evento desconhecido';

              return Card(
                elevation: 4,
                child: InkWell(
                  onTap: () {
                    if (urlArquivo != null) {
                      certificadosService.abrirCertificado(urlArquivo);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL do certificado inválido'),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nomeEvento,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Emitido em: ${certificado.createdAt?.toString().substring(0, 10) ?? 'Data desconhecida'}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Icon(Icons.download, color: Colors.blue),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}