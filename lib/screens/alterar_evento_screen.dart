import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:login_ui/service/Evento/Evento.dart'; // Importando o arquivo de serviços

class AlterarEventoScreen extends StatefulWidget {
  final String objectId;

  const AlterarEventoScreen({Key? key, required this.objectId})
      : super(key: key);

  @override
  _AlterarEventoScreenState createState() => _AlterarEventoScreenState();
}

class _AlterarEventoScreenState extends State<AlterarEventoScreen> {
  List<ParseObject> _eventos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    try {
      final eventos =
          await EventoAlterarService.carregarEventos(widget.objectId);
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarMensagemErro("Erro ao carregar eventos: $e");
    }
  }

  Future<void> _excluirEvento(ParseObject evento) async {
    try {
      await EventoAlterarService.excluirEvento(evento);
      setState(() {
        _eventos.remove(evento);
      });
      _mostrarMensagemErro("Evento excluído com sucesso.");
    } catch (e) {
      _mostrarMensagemErro("Erro ao excluir evento: $e");
    }
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void _editarEvento(ParseObject evento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarEventoScreen(evento: evento),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alterar Evento"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _eventos.isEmpty
              ? const Center(child: Text("Nenhum evento encontrado."))
              : ListView.builder(
                  itemCount: _eventos.length,
                  itemBuilder: (context, index) {
                    final evento = _eventos[index];
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                            evento.get<String>('NomeEvento') ?? "Sem nome"),
                        subtitle: Text(
                            evento.get<String>('Descricao') ?? "Sem descrição"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _excluirEvento(evento),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editarEvento(evento),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class EditarEventoScreen extends StatefulWidget {
  final ParseObject evento;

  const EditarEventoScreen({Key? key, required this.evento}) : super(key: key);

  @override
  _EditarEventoScreenState createState() => _EditarEventoScreenState();
}

class _EditarEventoScreenState extends State<EditarEventoScreen> {
  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _vagasController;
  DateTime? _dataInicio;
  DateTime? _dataFim;

  @override
void initState() {
  super.initState();
  _nomeController =
      TextEditingController(text: widget.evento.get<String>('NomeEvento'));
  _descricaoController =
      TextEditingController(text: widget.evento.get<String>('Descricao'));
  _vagasController = TextEditingController(
      text: widget.evento.get<int>('Vagas')?.toString() ?? '');

  // Carrega as datas sem ajustar as horas
  _dataInicio = widget.evento.get<DateTime>('DataInicio');
  _dataFim = widget.evento.get<DateTime>('DataFim');
}

Future<void> _selecionarDataInicio() async {
  final DateTime? dataSelecionada = await showDatePicker(
    context: context,
    initialDate: _dataInicio ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (dataSelecionada != null) {
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataInicio ?? DateTime.now()),
    );

    if (horaSelecionada != null) {
      setState(() {
        _dataInicio = DateTime.utc( // Usar DateTime.utc
          dataSelecionada.year,
          dataSelecionada.month,
          dataSelecionada.day,
          horaSelecionada.hour,
          horaSelecionada.minute,
        );
      });
    }
  }
}

Future<void> _selecionarDataFim() async {
  final DateTime? dataSelecionada = await showDatePicker(
    context: context,
    initialDate: _dataFim ?? DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  if (dataSelecionada != null) {
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dataFim ?? DateTime.now()),
    );

    if (horaSelecionada != null) {
      setState(() {
        _dataFim = DateTime.utc( // Usar DateTime.utc
          dataSelecionada.year,
          dataSelecionada.month,
          dataSelecionada.day,
          horaSelecionada.hour,
          horaSelecionada.minute,
        );
      });
    }
  }
}


Future<void> _salvarAlteracoes() async {
  try {
    await EventoAlterarService.salvarAlteracoes(
      widget.evento,
      _nomeController.text,
      _descricaoController.text,
      _dataInicio?.toUtc().toIso8601String() ?? '', // Converter para UTC
      _dataFim?.toUtc().toIso8601String() ?? '', // Converter para UTC
      _vagasController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Evento atualizado com sucesso!')),
    );
    Navigator.pop(context, true);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao atualizar o evento: $e')),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Evento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nome do Evento',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  hintText: 'Digite o nome do evento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Descrição',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Digite a descrição do evento',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data de Início',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ListTile(
                title: Text(
                  _dataInicio != null
                      ? '${_dataInicio!.day.toString().padLeft(2, '0')}/'
                          '${_dataInicio!.month.toString().padLeft(2, '0')}/'
                          '${_dataInicio!.year}'
                      : 'Selecione a data de início',
                ),
                subtitle: Text(
                  _dataInicio != null
                      ? '${_dataInicio!.hour.toString().padLeft(2, '0')}:'
                          '${_dataInicio!.minute.toString().padLeft(2, '0')}'
                      : 'Selecione o horário de início',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selecionarDataInicio,
              ),
              const SizedBox(height: 16),
              const Text(
                'Data de Fim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              ListTile(
                title: Text(
                  _dataFim != null
                      ? '${_dataFim!.day.toString().padLeft(2, '0')}/'
                          '${_dataFim!.month.toString().padLeft(2, '0')}/'
                          '${_dataFim!.year}'
                      : 'Selecione a data de fim',
                ),
                subtitle: Text(
                  _dataFim != null
                      ? '${_dataFim!.hour.toString().padLeft(2, '0')}:'
                          '${_dataFim!.minute.toString().padLeft(2, '0')}'
                      : 'Selecione o horário de fim',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selecionarDataFim,
              ),
              const SizedBox(height: 16),
              const Text(
                'Vagas',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              TextField(
                controller: _vagasController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Digite o número de vagas',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _salvarAlteracoes,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Salvar Alterações',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    super.dispose();
  }
}
