import 'package:flutter/material.dart';
import 'package:login_ui/screens/certificados_screen.dart';
import 'package:login_ui/screens/meus_evento_screen.dart';
import 'package:login_ui/screens/perfil_screen.dart';
import 'package:login_ui/screens/eventos_home_screen.dart';
import 'package:login_ui/screens/alterar_evento_screen.dart';
import 'package:login_ui/screens/cadastrar_evento_screen.dart';
import 'package:login_ui/service/Perfil/_User.dart'; // Importe o arquivo com as funções

class HomeScreen extends StatefulWidget {
  final String objectId;

  const HomeScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;
  bool _isProfessor = false;
  late HomeFunctions _homeFunctions; // Instância da classe de funções

  @override
  void initState() {
    super.initState();
    _homeFunctions = HomeFunctions(objectId: widget.objectId); // Inicializa a classe de funções
    _fetchUserType(); // Verifica o tipo do usuário na inicialização
  }

  Future<void> _fetchUserType() async {
    final isProfessor = await _homeFunctions.fetchUserType(); // Usa a função da classe
    setState(() {
      _isProfessor = isProfessor;
    });
  }

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
          CertificadosScreen(userObjectId: widget.objectId),
          HomeContent(objectId: widget.objectId),
          ProfileScreen(objectId: widget.objectId),
          MeusEventos(objectId: widget.objectId),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (index) {
          setState(() {
            _currentPage = index;
          });
          _pageController.jumpToPage(index);
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
      floatingActionButton: _isProfessor
          ? FloatingActionButton(
              backgroundColor: Colors.green[700],
              child: const Icon(Icons.menu),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Color.fromARGB(255, 19, 42, 72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (BuildContext context) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 36, color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => CadastroEventoScreen(objectId: widget.objectId),
                                        ),
                                      );
                                    },
                                  ),
                                  const Text("Cadastrar", style: TextStyle(fontSize: 14))
                                ],
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.build, size: 36, color: Colors.green),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AlterarEventoScreen(objectId: widget.objectId),
                                        ),
                                      );
                                    },
                                  ),
                                  const Text("Alterar", style: TextStyle(fontSize: 14))
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            )
          : null,
    );
  }
}