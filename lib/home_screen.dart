import 'package:flutter/material.dart';
import 'package:login_ui/login_screen.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart'; // Importando o pacote intl
import 'package:login_ui/inscrição.dart';

// Tela para Certificados
class CertificadosScreen extends StatelessWidget {
  const CertificadosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Certificados'),
        centerTitle: true,
        actions: [
          Row(
            children: [
              const Text('Sair'),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
            ],
          )
        ],
      ),
      body: const Center(child: Text('Aqui estarão os certificados')),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  final ParseUser? currentUser = await ParseUser.currentUser() as ParseUser?;

  if (currentUser != null) {
    final ParseResponse response = await currentUser.logout();
    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout realizado com sucesso!')),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginPage(title: 'Login')),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no logout: ${response.error?.message}')),
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nenhum usuário está logado.')),
    );
  }
}

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
            'NomeEvento': evento?.get<String>('NomeEvento') ?? 'Sem Nome',
            'Descricao': evento?.get<String>('Descricao') ?? 'Sem descrição',
            'DataInicio': evento?.get<DateTime>('DataInicio') ?? DateTime.now(),
            'DataFim': evento?.get<DateTime>('DataFim') ?? DateTime.now(),
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
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

                return _buildEventCard(
                    evento, startDate, startTime, endDate, endTime);
              },
            );
          }
        },
      ),
    );
  }

  // Método para criar o card do evento
  Widget _buildEventCard(Map<String, dynamic> evento, String startDate,
      String startTime, String endDate, String endTime) {
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
          MeusEventos(objectId: widget.objectId), // Tela de Meus Eventos
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
              builder: (context) =>
                  CadastroEventoScreen(objectId: widget.objectId),
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
          'objectId': evento.objectId,
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
                onPressed: () => _logout(context),
              ),
            ],
          ),
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
                                  await inscreverUsuarioEmEvento(
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

                        // Inscrever no evento

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

class ProfileScreen extends StatefulWidget {
  final String objectId;

  ProfileScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Carregando..."; // Texto inicial enquanto carrega o nome

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Chama o método para buscar o nome do usuário
  }

  Future<void> _fetchUserName() async {
    try {
      // Cria a query para buscar na tabela "Usuario"
      final query = QueryBuilder<ParseObject>(ParseObject('_User'))
        ..whereEqualTo('objectId', widget.objectId);

      // Executa a query
      final response = await query.query();

      if (response.success && response.results != null) {
        final usuario = response.results!.first as ParseObject;
        final name = usuario.get<String>('Nome') ?? 'Nome não encontrado';
        setState(() {
          userName = name; // Atualiza o estado com o nome do usuário
        });
      } else {
        setState(() {
          userName = 'Usuário não encontrado';
        });
      }
    } catch (e) {
      setState(() {
        userName = 'Erro ao buscar nome';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Usuário'),
        actions: [
          Row(
            children: [
              const Text('Sair'),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _logout(context),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: Text(
          'Nome do usuário: $userName', // Exibe o nome do usuário
          style: const TextStyle(fontSize: 18),
        ),
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
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _vagasController = TextEditingController();

  DateTime _dataInicio = DateTime.now();
  DateTime _dataFim = DateTime.now();
  double _latitude = 0.0;
  double _longitude = 0.0;

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _vagasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final DateTime picked = await showDatePicker(
          context: context,
          initialDate: isInicio ? _dataInicio : _dataFim,
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
        ) ??
        DateTime.now();

    setState(() {
      if (isInicio) {
        _dataInicio = picked;
      } else {
        _dataFim = picked;
      }
    });
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
        } else {
          _dataFim = DateTime(
            _dataFim.year,
            _dataFim.month,
            _dataFim.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

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
        SnackBar(
            content: Text(
                'Erro: objectId do usuário não foi passado corretamente.')),
      );
      return;
    }

    // Criar um objeto de evento no Parse
    var evento = ParseObject('Evento')
      ..set('NomeEvento', _nomeController.text)
      ..set('Descricao', _descricaoController.text)
      ..set('DataInicio', _dataInicio)
      ..set('DataFim', _dataFim)
      ..set('Vagas', int.parse(_vagasController.text))
      ..set('Lat', _latitude)
      ..set('Long', _longitude)
      // Configurar o campo idUsuario como um Pointer
      ..set('idUsuario', ParseObject('_User')..objectId = widget.objectId);

    try {
      var response = await evento.save();
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evento cadastrado com sucesso!')),
        );
        Navigator.pop(context); // Voltar para a tela anterior
      } else {
        String errorMessage = response.error?.message ?? 'Erro desconhecido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar o evento: $errorMessage')),
        );
      }
    } catch (e) {
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
            Row(
              children: [
                Expanded(
                  child: Text(
                      'Data Início: ${_dataInicio.toLocal().toString().split(' ')[0]}'),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                      'Data Fim: ${_dataFim.toLocal().toString().split(' ')[0]}'),
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
