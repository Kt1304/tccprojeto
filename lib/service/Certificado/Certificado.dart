import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle; // Para mobile
import 'package:http/http.dart' as http; //
import 'package:pdf/pdf.dart';

class CertificadosService {
  final String userObjectId;

  CertificadosService({required this.userObjectId});

  Future<List<ParseObject>> buscarCertificados(BuildContext context) async {
    try {
      final inscricaoQuery = QueryBuilder(ParseObject('Inscricao'))
        ..whereEqualTo(
            'IdUsuario', ParseObject('_User')..objectId = userObjectId)
        ..includeObject(['IdEvento']);

      final inscricaoResponse = await inscricaoQuery.query();

      if (!inscricaoResponse.success || inscricaoResponse.results == null) {
        throw Exception('Nenhuma inscrição encontrada');
      }

      List<ParseObject> todosCertificados = [];

      for (final inscricao in inscricaoResponse.results!.cast<ParseObject>()) {
        final evento = inscricao.get<ParseObject>('IdEvento');

        final certificadoQuery = QueryBuilder(ParseObject('Certificado'))
          ..whereEqualTo('IdInscricao', inscricao)
          ..includeObject(['IdInscricao']);

        final certificadoResponse = await certificadoQuery.query();

        if (certificadoResponse.success &&
            certificadoResponse.results != null) {
          for (final certificado
              in certificadoResponse.results!.cast<ParseObject>()) {
            certificado.set(
                'evento', evento); // Adiciona o evento ao certificado
            todosCertificados.add(certificado);
          }
        }
      }

      return todosCertificados;
    } catch (e) {
      throw Exception('Erro ao buscar certificados: ${e.toString()}');
    }
  }

  Future<void> abrirCertificado(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível abrir o certificado';
    }
  }
}

class CertificadoScreen extends StatelessWidget {
  final String nomeEvento;
  final String descricaoEvento;
  final String idInscricao;

  const CertificadoScreen({
    Key? key,
    required this.nomeEvento,
    required this.descricaoEvento,
    required this.idInscricao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gerar Certificado'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            try {
              await PdfService.gerarESalvarPdfCertificado(
                nomeEvento,
                descricaoEvento,
                idInscricao,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Certificado gerado e salvo com sucesso!'),
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao gerar certificado: $e'),
                ),
              );
            }
          },
          child: Text('Gerar Certificado'),
        ),
      ),
    );
  }
}

class PdfService {
  static Future<void> gerarESalvarPdfCertificado(
    String nomeEvento,
    String descricaoEvento,
    String idInscricao,
  ) async {
    final pdf = pw.Document();

    final Uint8List logoBytes;
    final Uint8List fundoBytes;

    try {
      if (kIsWeb) {
        final logoResponse = await http.get(Uri.parse(
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBoBGCfBTDL-sHFj2kWebAs9jB5qtQuGfYRQ&s'));
        final fundoResponse = await http.get(
            Uri.parse('https://st3.depositphotos.com/2313745/14740/i/450/depositphotos_147404437-stock-illustration-insulated-frame-background-template-for.jpg'));

        if (logoResponse.statusCode != 200 || fundoResponse.statusCode != 200) {
          throw Exception('Erro ao carregar imagens');
        }
        logoBytes = logoResponse.bodyBytes;
        fundoBytes = fundoResponse.bodyBytes;
      } else {
        logoBytes =
            (await rootBundle.load('assets/logo.png')).buffer.asUint8List();
        fundoBytes = (await rootBundle.load('assets/fundo_certificado.jpg'))
            .buffer
            .asUint8List();
      }

      final logo = pw.MemoryImage(logoBytes);
      final fundo = pw.MemoryImage(fundoBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Stack(
              children: [
                // Imagem de fundo preenchendo toda a página sem moldura
                pw.Positioned.fill(
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      image: pw.DecorationImage(
                        image: fundo,
                        fit: pw.BoxFit
                            .fill, // Garante que a imagem preencha toda a página sem bordas
                      ),
                    ),
                  ),
                ),
                // Conteúdo do certificado
                pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // Logo no topo centralizado
                      pw.Image(logo, width: 120, height: 120),
                      pw.SizedBox(height: 20),
                      // Título do certificado
                      pw.Text(
                        'Certificado de Participação',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      // Nome do evento
                      pw.Text(
                        nomeEvento,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.black,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      // Descrição do evento
                      pw.Text(
                        descricaoEvento,
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.grey800,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 20),
                      // ID de inscrição
                      pw.Text(
                        'ID de Inscrição: $idInscricao',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontStyle: pw.FontStyle.italic,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();
      final parseFile = ParseWebFile(
        bytes,
        name: 'certificado_$idInscricao.pdf',
      );
      final saveFileResponse = await parseFile.save();

      if (saveFileResponse.success) {
        final query = QueryBuilder(ParseObject('Certificado'))
          ..whereEqualTo('IdInscricao',
              ParseObject('Inscricao')..set('objectId', idInscricao));
        final certificadoResponse = await query.query();

        if (certificadoResponse.success &&
            certificadoResponse.results != null &&
            certificadoResponse.results!.isNotEmpty) {
          return;
        }

        final inscricaoQuery = QueryBuilder(ParseObject('Inscricao'))
          ..whereEqualTo('objectId', idInscricao);
        final inscricaoResponse = await inscricaoQuery.query();

        if (inscricaoResponse.success &&
            inscricaoResponse.results != null &&
            inscricaoResponse.results!.isNotEmpty) {
          final inscricao = inscricaoResponse.results!.first;

          final certificado = ParseObject('Certificado')
            ..set('IdInscricao', inscricao)
            ..set('arquivo', parseFile);

          final response = await certificado.save();

          if (response.success && kIsWeb) {
            final blob = html.Blob([bytes], 'application/pdf');
            final url = html.Url.createObjectUrlFromBlob(blob);
            final anchor = html.AnchorElement(href: url)
              ..setAttribute('download', 'certificado_$idInscricao.pdf')
              ..click();
            html.Url.revokeObjectUrl(url);
          }
        }
      }
    } catch (e) {
      print('Erro ao gerar ou salvar o PDF: $e');
      rethrow;
    }
  }
}
