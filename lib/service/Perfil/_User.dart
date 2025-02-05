import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:login_ui/screens/login_screen.dart';

// Formatters
final cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
final telefoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

// Services
class CadastroService {
  Future<bool> verificaDuplicidade(String campo, String valor) async {
    final QueryBuilder<ParseObject> query =
        QueryBuilder<ParseObject>(ParseObject('Usuario'))
          ..whereEqualTo(campo, valor);

    final ParseResponse response = await query.query();
    return response.results != null && response.results!.isNotEmpty;
  }

  Future<void> inserirUsuario({
    required String nome,
    required String cpf,
    required String telefone,
    required String email,
    required String cidade,
    required String estado,
    required String senha,
    required String confirmarSenha,
    required String tipoUsuario, // Novo parâmetro
    required BuildContext context,
  }) async {
    bool cpfExiste = await verificaDuplicidade('Cpf', cpf);
    bool emailExiste = await verificaDuplicidade('Email', email);

    if (senha != confirmarSenha) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem!')),
      );
      return;
    }

    if (cpfExiste || emailExiste) {
      String mensagemErro = '';
      if (cpfExiste) {
        mensagemErro += 'O CPF já está cadastrado.\n';
      }
      if (emailExiste) {
        mensagemErro += 'O e-mail já está cadastrado.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemErro)),
      );
      return;
    }

    // Definição do status de validação
    bool validado = tipoUsuario == 'aluno';

    final ParseUser usuario = ParseUser(email, senha, email)
      ..set<String>('Nome', nome)
      ..set<String>('Cpf', cpf)
      ..set<String>('Telefone', telefone)
      ..set<String>('Email', email)
      ..set<String>('Cidade', cidade)
      ..set<String>('Estado', estado)
      ..set<String>('Senha', senha)
      ..set<String>('Tipo_Usuario', tipoUsuario)
      ..set<bool>('Validado', validado); // Define o status de validação

    final response = await usuario.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );

      // Exibir aviso se for professor
      if (!validado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Seu cadastro será analisado. A autorização será concedida em até 3 dias úteis.',
            ),
          ),
        );
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao cadastrar! Tente novamente')),
      );
    }
  }

  Future<void> pickFile({
    required Function(String?) onFilePicked,
  }) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);

    if (result != null) {
      onFilePicked(result.files.first.name);
    }
  }
}

class RecuperarSenhaService {
  final BuildContext context;

  RecuperarSenhaService(this.context);

  Future<void> recuperarSenha(String email) async {
    final ParseUser user = ParseUser(null, null, email);

    final ParseResponse response = await user.requestPasswordReset();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de recuperação enviado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.error?.message ?? 'Erro ao enviar email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Repository
class UserRepository {
  Future<ParseObject?> fetchUserData(String objectId) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('_User'))
        ..whereEqualTo('objectId', objectId);

      final response = await query.query();

      if (response.success && response.results != null) {
        return response.results!.first as ParseObject;
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }

  Future<bool> updateUserInfo(String objectId, Map<String, String> userData) async {
    try {
      final parseObject = ParseObject('_User')..objectId = objectId;
      userData.forEach((key, value) {
        parseObject.set<String>(key, value);
      });

      final response = await parseObject.save();
      return response.success;
    } catch (e) {
      return false;
    }
  }
}

// Utils
Future<void> fetchUserData(String objectId, Function(ParseObject) onSuccess, Function onError) async {
  try {
    final query = QueryBuilder<ParseObject>(ParseObject('_User'))
      ..whereEqualTo('objectId', objectId);

    final response = await query.query();

    if (response.success && response.results != null) {
      final usuario = response.results!.first as ParseObject;
      onSuccess(usuario);
    } else {
      onError();
    }
  } catch (e) {
    onError();
  }
}

Widget buildUserInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 30, color: Colors.green),
      const SizedBox(width: 10),
      Text('$label: $value', style: const TextStyle(fontSize: 16)),
    ],
  );
}

class HomeFunctions {
  final String objectId;

  HomeFunctions({required this.objectId});

  // Função para buscar o tipo de usuário
  Future<bool> fetchUserType() async {
    try {
      final query = ParseObject('_User')..objectId = objectId;
      final response = await query.getObject(objectId);

      if (response.success && response.result != null) {
        final user = response.result;
        return user.get<String>('Tipo_Usuario') == 'professor';
      }
    } catch (e) {
      print("Erro ao buscar tipo de usuário: $e");
    }
    return false;
  }
}
