import 'package:flutter/material.dart';
import 'package:login_ui/service/Perfil/_User.dart';

class EditProfileScreen extends StatefulWidget {
  final String objectId;

  EditProfileScreen({Key? key, required this.objectId}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepository = UserRepository();

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Busca os dados do usuário para preencher os campos
  }

  Future<void> _fetchUserData() async {
    final usuario = await _userRepository.fetchUserData(widget.objectId);
    if (usuario != null) {
      _nameController.text = usuario.get<String>('Nome') ?? '';
      _cityController.text = usuario.get<String>('Cidade') ?? '';
      _stateController.text = usuario.get<String>('Estado') ?? '';
      _phoneController.text = usuario.get<String>('Telefone') ?? '';
    }
  }

  Future<void> _updateUserInfo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final userData = {
        'Nome': _nameController.text,
        'Cidade': _cityController.text,
        'Estado': _stateController.text,
        'Telefone': _phoneController.text,
      };

      final success = await _userRepository.updateUserInfo(widget.objectId, userData);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dados atualizados com sucesso!')),
        );
        Navigator.pop(context); // Volta para a tela anterior após atualizar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar dados')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Campo de nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Campo de cidade
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Cidade'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a cidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Campo de estado
              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(labelText: 'Estado'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o estado';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),

              // Campo de telefone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o telefone';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botão de atualização
              ElevatedButton(
                onPressed: _updateUserInfo,
                child: const Text('Atualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}