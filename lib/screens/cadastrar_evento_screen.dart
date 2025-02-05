import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:login_ui/service/Evento/Evento.dart'; // Importe o serviço que criamos
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


class CadastroEventoScreen extends StatefulWidget {
  final String objectId;

  CadastroEventoScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _CadastroEventoScreenState createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _vagasController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now();

  final EventoService _eventoService = EventoService();

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = picked;
        } else {
          _dataFim = picked;
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isInicio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isInicio ? _dataInicio : _dataFim),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = DateTime(
            _dataInicio.year,
            _dataInicio.month,
            _dataInicio.day,
            picked.hour,
            picked.minute,
          );
          _dataInicio = _dataInicio.subtract(Duration(hours: 3)); // Subtrai 3 horas
        } else {
          _dataFim = DateTime(
            _dataFim.year,
            _dataFim.month,
            _dataFim.day,
            picked.hour,
            picked.minute,
          );
          _dataFim = _dataFim.subtract(Duration(hours: 3)); // Subtrai 3 horas
        }
      });
    }
  }

  Future<void> _cadastrarEvento() async {
    if (_nomeController.text.isEmpty ||
        _descricaoController.text.isEmpty ||
        _vagasController.text.isEmpty) {
      _showSnackBar('Por favor, preencha todos os campos');
      return;
    }

    if (widget.objectId.isEmpty) {
      _showSnackBar('Erro: objectId do usuário não foi passado corretamente.');
      return;
    }

    ParseUser? currentUser;
    try {
      currentUser = await ParseUser.currentUser() as ParseUser?;
      if (currentUser == null) {
        _showSnackBar('Erro: Nenhum usuário logado encontrado.');
        return;
      }
    } catch (e) {
      _showSnackBar('Erro ao obter o usuário atual: $e');
      return;
    }

    Position position;
    try {
      position = await _eventoService.getCurrentLocation();
    } catch (e) {
      _showSnackBar('Erro ao obter a localização: $e');
      return;
    }

    String idInstituicao = 'rHvEmKTciH'; // Substitua pelo ID correto

    try {
      await _eventoService.cadastrarEvento(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        dataInicio: _dataInicio,
        dataFim: _dataFim,
        vagas: int.parse(_vagasController.text),
        position: position,
        idUsuario: currentUser.objectId!,
        idInstituicao: idInstituicao,
      );

      _showSnackBar('Evento cadastrado com sucesso!');
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erro ao cadastrar o evento: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Evento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _buildTextField(_nomeController, 'Nome do Evento'),
            const SizedBox(height: 16),
            _buildTextField(_descricaoController, 'Descrição'),
            const SizedBox(height: 16),
            _buildDateTimePicker(
              label: 'Data Início',
              date: _dataInicio,
              onDatePressed: () => _selectDate(context, true),
              onTimePressed: () => _selectTime(context, true),
            ),
            const SizedBox(height: 16),
            _buildDateTimePicker(
              label: 'Data Fim',
              date: _dataFim,
              onDatePressed: () => _selectDate(context, false),
              onTimePressed: () => _selectTime(context, false),
            ),
            const SizedBox(height: 16),
            _buildTextField(_vagasController, 'Vagas', isNumber: true),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cadastrarEvento,
              child: const Text('Cadastrar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required DateTime date,
    required VoidCallback onDatePressed,
    required VoidCallback onTimePressed,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${date.toLocal().toString().split(' ')[0]}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: onDatePressed,
        ),
        IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: onTimePressed,
        ),
      ],
    );
  }
}