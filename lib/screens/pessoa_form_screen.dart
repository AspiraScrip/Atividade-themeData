import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class PessoaFormScreen extends StatefulWidget {
  final int usuarioId;
  final Map<String, Object?>? pessoa;

  const PessoaFormScreen({super.key, required this.usuarioId, this.pessoa});

  @override
  State<PessoaFormScreen> createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends State<PessoaFormScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final telefoneController = TextEditingController();

  bool salvando = false;

  bool get editando => widget.pessoa != null;

  @override
  void initState() {
    super.initState();

    final pessoa = widget.pessoa;

    if (pessoa != null) {
      nomeController.text = pessoa['nome'] as String;
      emailController.text = pessoa['email'] as String;
      telefoneController.text = pessoa['telefone'] as String;
    }
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    telefoneController.dispose();
    super.dispose();
  }

  void mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> salvar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final telefone = telefoneController.text.trim();

    if (nome.isEmpty || email.isEmpty || telefone.isEmpty) {
      mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (!email.contains('@')) {
      mostrarMensagem('Informe um e-mail válido.');
      return;
    }

    setState(() => salvando = true);

    try {
      if (editando) {
        await DatabaseHelper.instance.atualizarPessoa(
          widget.pessoa!['id'] as int,
          widget.usuarioId,
          nome,
          email,
          telefone,
        );
      } else {
        await DatabaseHelper.instance.inserirPessoa(
          widget.usuarioId,
          nome,
          email,
          telefone,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro) {
      if (mounted) {
        mostrarMensagem('Erro ao salvar os dados da pessoa.');
      }
    } finally {
      if (mounted) {
        setState(() => salvando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editando ? 'Editar pessoa' : 'Cadastrar pessoa'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            editando ? Icons.edit_note : Icons.person_add_alt_1,
            size: 64,
            color: Colors.indigo,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nomeController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: telefoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: salvando ? null : salvar,
              icon: const Icon(Icons.save_outlined),
              label: Text(salvando ? 'Salvando...' : 'Salvar'),
            ),
          ),
        ],
      ),
    );
  }
}
