import 'package:flutter/material.dart';
import 'package:login_ui/service/SairService.dart';
import 'package:login_ui/service/Perfil/_User.dart';
import 'editar_perfil_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String objectId;

  ProfileScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Carregando...";
  String email = "Carregando...";
  String phone = "Carregando...";
  String city = "";
  String state = "";

  @override
  void initState() {
    super.initState();
    fetchUserData(
      widget.objectId,
      (usuario) {
        setState(() {
          userName = usuario.get<String>('Nome') ?? 'Nome não encontrado';
          email = usuario.get<String>('email') ?? 'Email não encontrado';
          phone = usuario.get<String>('Telefone') ?? 'Telefone não encontrado';
          city = usuario.get<String>('Cidade') ?? '';
          state = usuario.get<String>('Estado') ?? '';
        });
      },
      () {
        setState(() {
          userName = 'Erro ao buscar dados';
        });
      },
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildUserInfoRow(Icons.person, 'Nome', userName),
        const SizedBox(height: 16),
        buildUserInfoRow(Icons.email, 'Email', email),
        const SizedBox(height: 16),
        buildUserInfoRow(Icons.phone, 'Telefone', phone),
        const SizedBox(height: 20),
        const Divider(),
        buildUserInfoRow(Icons.location_city, 'Cidade', city),
        const SizedBox(height: 16),
        buildUserInfoRow(Icons.map, 'Estado', state),
      ],
    );
  }

  Widget _buildEditProfileButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditProfileScreen(objectId: widget.objectId),
          ),
        );
      },
      child: const Text('Editar Perfil'),
    );
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
                onPressed: () => logout(context),
              ),
            ],
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileInfo(),
              const SizedBox(height: 20),
              _buildEditProfileButton(),
            ],
          ),
        ),
      ),
    );
  }
}
