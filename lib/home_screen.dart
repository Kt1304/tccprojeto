import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl

// Tela para Certificados
class CertificadosScreen extends StatelessWidget {
  const CertificadosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Certificados')),
      body: const Center(child: Text('Aqui estarão os certificados')),
    );
  }
}

// Tela para Meus Eventos
class MeusEventos extends StatefulWidget {
  const MeusEventos({Key? key}) : super(key: key);

  @override
  _MeusEventosState createState() => _MeusEventosState();
}

class _MeusEventosState extends State<MeusEventos> {
  late Future<List<Map<String, dynamic>>> inscricoesFuturas;

  Future<List<Map<String, dynamic>>> _fetchInscricoes() async {
    final user = await ParseUser.currentUser() as ParseUser?;

    if (user == null) {
      throw Exception('Usuário não está autenticado');
    }

    final query = QueryBuilder(ParseObject('Inscricao'))
      ..whereEqualTo('IdUsuario', user)
      ..includeObject(['IdEvento']); // Carregar detalhes do evento

    final response = await query.query();

    if (response.success && response.results != null) {
      List<Map<String, dynamic>> eventos = [];
      for (var inscricao in response.results!) {
        final evento = inscricao.get<ParseObject>('evento');
        if (evento != null) {
          eventos.add({
            'NomeEvento': evento.get<String>('NomeEvento') ?? 'Sem Nome',
            'Descricao': evento.get<String>('Descricao') ?? 'Sem descrição',
            'DataInicio': evento.get<DateTime>('DataInicio') ?? DateTime.now(),
            'DataFim': evento.get<DateTime>('DataFim') ?? DateTime.now(),
          });
        }
      }
      return eventos;
    } else {
      throw Exception('Erro ao carregar inscrições');
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
      appBar: AppBar(centerTitle: true, title: const Text('Meus Eventos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: inscricoesFuturas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma inscrição encontrada.'));
          } else {
            final eventos = snapshot.data!;
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
                final endTime =
                    DateFormat('HH:mm').format(evento['DataFim'] as DateTime);

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
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Tela de Eventos (Home)
class HomeScreen extends StatefulWidget {
  final String objectId; // Variável para armazenar o objectId

  // Construtor que recebe o objectId como parâmetro
  const HomeScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  // Função para navegar para as telas ao deslizar
  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          CertificadosScreen(), // Primeira tela (Certificados)
          HomeContent(objectId: widget.objectId), // Tela inicial (Eventos)
          ProfileScreen(objectId: widget.objectId), // Tela de Perfil
          MeusEventos(), // Tela de Meus Eventos
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
          _pageController
              .jumpToPage(index); // Muda para a página com base no índice
        },
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.green[400],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in, size: 40),
            label: 'Certificados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 40),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person, size: 40),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event, size: 40),
            label: 'Meus Eventos',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CadastroEventoScreen(
                  objectId: widget.objectId),
            ),
          );
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Tela de conteúdo da Home (Eventos)
class HomeContent extends StatefulWidget {
  final String objectId;
  const HomeContent({Key? key, required this.objectId}) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Future<List<Map<String, dynamic>>> eventosFuturos;

  // Função para buscar eventos no banco de dados
  Future<List<Map<String, dynamic>>> _fetchEventos() async {
    final query = QueryBuilder(ParseObject('Evento'))
      ..orderByAscending('DataInicio');

    final response = await query.query();

    if (response.success && response.results != null) {
      List<Map<String, dynamic>> eventos = [];
      for (var evento in response.results!) {
        eventos.add({
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

  @override
  void initState() {
    super.initState();
    eventosFuturos = _fetchEventos();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
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
                      onPressed: () {
                        // Inscrever no evento
                      },
                      child: const Text('Inscrever-se'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
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
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final String objectId; // Adicione um campo para armazenar o objectId

  // Construtor que recebe o objectId
  ProfileScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
            'Perfil do usuário - Object ID: $objectId'), // Exibe o Object ID no texto
      ),
    );
  }
}


class CadastroEventoScreen extends StatefulWidget {
  final String objectId;
  CadastroEventoScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _CadastroEventoScreenState createState() => _CadastroEventoScreenState();
}

class _CadastroEventoScreenState extends State<CadastroEventoScreen> {
  // Controladores para capturar os dados
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _vagasController = TextEditingController();

  // Variáveis para data e hora
  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now();

  // Padrão para latitude e longitude
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    super.dispose();
  }

  // Função para abrir o seletor de data
  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    ) ?? DateTime.now();

    setState(() {
      if (isInicio) {
        _dataInicio = picked;
      } else {
        _dataFim = picked;
      }
    });
  }

  // Função para abrir o seletor de hora
  Future<void> _selectTime(BuildContext context, bool isInicio) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(isInicio ? _dataInicio : _dataFim),
    );

    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = DateTime(_dataInicio.year, _dataInicio.month, _dataInicio.day, picked.hour, picked.minute);
        } else {
          _dataFim = DateTime(_dataFim.year, _dataFim.month, _dataFim.day, picked.hour, picked.minute);
        }
      });
    }
  }

  // Função para cadastrar o evento
  Future<void> _cadastrarEvento() async {
    if (_nomeController.text.isEmpty ||
        _descricaoController.text.isEmpty ||
        _vagasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos')),
      );
      return;
    }

    if (widget.objectId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: objectId do usuário não foi passado corretamente.')),
      );
      return;
    }

    // Criar um objeto de evento no Parse
    var evento = ParseObject('Evento')
      ..set('NomeEvento', _nomeController.text)
      ..set('Descricao', _descricaoController.text)
      ..set('DataInicio', _dataInicio)  // Enviando diretamente o DateTime
      ..set('DataFim', _dataFim)       // Enviando diretamente o DateTime
      ..set('Vagas', int.parse(_vagasController.text))
      ..set('Lat', _latitude)
      ..set('Long', _longitude);

    // Criando o objeto Usuario e atribuindo o id do usuário
    var usuario = ParseObject('Usuario')..objectId = widget.objectId;
    evento.set('idUsuario', usuario);

    try {
      var response = await evento.save();
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evento cadastrado com sucesso!')),
        );
        Navigator.pop(context); // Voltar para a tela anterior
      } else {
        // Exibir mensagem de erro com o conteúdo detalhado
        String errorMessage = response.error?.message ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar o evento. Erro: $errorMessage')),
        );
      }
    } catch (e) {
      // Capturar erros de rede ou outros erros
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastrar Evento')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _nomeController,
              decoration: const InputDecoration(labelText: 'Nome do Evento'),
            ),
            TextField(
              controller: _descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            // Data de Início
            Row(
              children: [
                Expanded(
                  child: Text('Data Início: ${_dataInicio.toLocal().toString().split(' ')[0]}'),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: const Text('Selecionar Data'),
                ),
                ElevatedButton(
                  onPressed: () => _selectTime(context, true),
                  child: const Text('Selecionar Hora'),
                ),
              ],
            ),
            // Data de Fim
            Row(
              children: [
                Expanded(
                  child: Text('Data Fim: ${_dataFim.toLocal().toString().split(' ')[0]}'),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context, false),
                  child: const Text('Selecionar Data'),
                ),
                ElevatedButton(
                  onPressed: () => _selectTime(context, false),
                  child: const Text('Selecionar Hora'),
                ),
              ],
            ),
            TextField(
              controller: _vagasController,
              decoration: const InputDecoration(labelText: 'Vagas'),
              keyboardType: TextInputType.number,
            ),
            // Botão de Cadastro
            ElevatedButton(
              onPressed: _cadastrarEvento,
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}