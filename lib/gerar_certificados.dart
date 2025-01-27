import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

Future<void> gerarCertificadoAluno(
    String alunoId, String eventoId, BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  var alunoQuery = QueryBuilder<ParseObject>(ParseObject('_User'))
    ..whereEqualTo('objectId', alunoId);
  var alunoResponse = await alunoQuery.query();
  if (!alunoResponse.success || alunoResponse.results == null) {
    Navigator.pop(context);
    return;
  }
  var aluno = alunoResponse.results!.first;

  var eventoQuery = QueryBuilder<ParseObject>(ParseObject('Evento'))
    ..whereEqualTo('objectId', eventoId);
  var eventoResponse = await eventoQuery.query();
  if (!eventoResponse.success || eventoResponse.results == null) {
    Navigator.pop(context);
    return;
  }
  var evento = eventoResponse.results!.first;

  final pdfBytes = await _gerarPdfCertificado(aluno, evento);
  final directory = await getTemporaryDirectory();
  final filePath =
      "${directory.path}/certificado_${aluno.get<String>('nome')}.pdf";
  final file = File(filePath);
  await file.writeAsBytes(pdfBytes);

  final parseFile = ParseFile(file);
  var fileResponse = await parseFile.save();
  if (!fileResponse.success) {
    Navigator.pop(context);
    return;
  }

  var certificado = ParseObject('Certificado')
    ..set('IdAluno', aluno.objectId)
    ..set('arquivo', parseFile)
    ..set('data_emissao', DateTime.now());

  await certificado.save();
  Navigator.pop(context);
}

Future<Uint8List> _gerarPdfCertificado(
    ParseObject aluno, ParseObject evento) async {
  final pdf = pw.Document();
  final font = await PdfGoogleFonts.robotoItalic();

  pdf.addPage(pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Text('Certificado de Participação',
                style: pw.TextStyle(
                    fontSize: 24, font: font, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Certificamos que',
                style: pw.TextStyle(fontSize: 18, font: font)),
            pw.Text(aluno.get<String>('Nome') ?? 'Aluno Desconhecido',
                style: pw.TextStyle(
                    fontSize: 18, font: font, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text('Participou do evento',
                style: pw.TextStyle(fontSize: 18, font: font)),
            pw.Text(evento.get<String>('Descricao') ?? 'Evento Desconhecido',
                style: pw.TextStyle(
                    fontSize: 18, font: font, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 20),
            pw.Text(
                'Em ${evento.get<DateTime>('DataInicio')?.toLocal().toString().split(' ')[0] ?? 'Data não informada'}',
                style: pw.TextStyle(fontSize: 18, font: font)),
          ],
        ),
      );
    },
  ));

  return await pdf.save();
}
