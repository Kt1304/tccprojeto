import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> gerarCertificados(String eventoId, BuildContext context) async {
  // Mostrar o loader
  showDialog(
    context: context,
    barrierDismissible: false, // Impede o fechamento com clique fora
    builder: (context) => Center(child: CircularProgressIndicator()),
  );

  var inscricoesQuery = QueryBuilder<ParseObject>(ParseObject('Inscricao'))
    ..whereEqualTo(
        'IdEvento', ParseObject('Inscricao')..set('IdEvento', eventoId));
  var inscricoesResponse = await inscricoesQuery.query();

  if (inscricoesResponse.success && inscricoesResponse.results != null) {
    for (var inscricao in inscricoesResponse.results!) {
      String? alunoId = inscricao.get<ParseObject>('aluno')?.objectId;

      if (alunoId == null) {
        print("Erro: Inscrição sem aluno vinculado.");
        continue;
      }

      // Buscar informações do aluno
      var alunoQuery = QueryBuilder<ParseObject>(ParseObject('Aluno'))
        ..whereEqualTo('objectId', alunoId);
      var alunoResponse = await alunoQuery.query();
      if (!alunoResponse.success || alunoResponse.results == null) {
        print("Erro ao buscar dados do aluno.");
        continue;
      }
      var aluno = alunoResponse.results!.first;

      // Buscar informações do evento
      var eventoQuery = QueryBuilder<ParseObject>(ParseObject('Evento'))
        ..whereEqualTo('objectId', eventoId);
      var eventoResponse = await eventoQuery.query();
      if (!eventoResponse.success || eventoResponse.results == null) {
        print("Erro ao buscar dados do evento.");
        continue;
      }
      var evento = eventoResponse.results!.first;

      // Gerar o PDF do certificado
      final pdfBytes = await gerarPdfCertificado(aluno, evento);

      // Salvar o arquivo localmente antes de enviar para o Parse
      final directory = await getTemporaryDirectory();
      final filePath =
          "${directory.path}/certificado_${aluno.get<String>('nome')}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Criar ParseFile para upload
      final parseFile = ParseFile(file);

      // Salvar arquivo no Parse antes de criar o registro do certificado
      var fileResponse = await parseFile.save();
      if (!fileResponse.success) {
        print("Erro ao salvar arquivo no Parse.");
        continue;
      }

      // Criar registro na tabela Certificado
      var certificado = ParseObject('Certificado')
        ..set('IdInscricao', inscricao.objectId)
        ..set('arquivo', parseFile)
        ..set('data_emissao', DateTime.now());

      var saveResponse = await certificado.save();
      if (saveResponse.success) {
        print(
            'Certificado salvo com sucesso para ${aluno.get<String>('nome')}');
      } else {
        print('Erro ao salvar certificado.');
      }
    }
  } else {
    print("Nenhuma inscrição encontrada para o evento.");
  }

  // Fechar o loader após finalizar
  Navigator.pop(context);
}

Future<Uint8List> gerarPdfCertificado(
    ParseObject aluno, ParseObject evento) async {
  final pdf = pw.Document();

  final logoIFPR =
      (await rootBundle.load('assets/imag/ifpr_logo.png')).buffer.asUint8List();
  final logoSigga = (await rootBundle.load('assets/imag/sigga_logo.png'))
      .buffer
      .asUint8List();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(pw.MemoryImage(logoIFPR), width: 100, height: 100),
                pw.Image(pw.MemoryImage(logoSigga), width: 100, height: 100),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Text('INSTITUTO FEDERAL DO PARANÁ, CAMPUS PALMAS',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            pw.Text('Atesta a participação de:',
                style: pw.TextStyle(fontSize: 20),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 10),
            pw.Text(aluno.get<String>('nome')!,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            pw.Text(
                'No evento realizado em ${evento.get<DateTime>('data')?.toLocal().toString().substring(0, 10)}',
                style: pw.TextStyle(fontSize: 18),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 20),
            pw.Text('Pela professor(a) ${evento.get<String>('professor')}',
                style: pw.TextStyle(fontSize: 18),
                textAlign: pw.TextAlign.center),
          ],
        );
      },
    ),
  );

  return await pdf.save();
}
