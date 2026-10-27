import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import 'login_screen.dart';
import 'pessoa_form_screen.dart';

class HomeScreen extends StatefulWidget {
  final int usuarioId;

  const HomeScreen({super.key, required this.usuarioId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, Object?>> pessoas = [];
  String nomeUsuario = 'Usuário';
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregarDados();
  }

  Future<void> carregarDados() async {
    try {
      final preferencias = await SharedPreferences.getInstance();

      final nome = preferencias.getString('nomeUsuario') ?? 'Usuário';

      final lista = await DatabaseHelper.instance.listarPessoas(
        widget.usuarioId,
      );

      if (!mounted) return;

      setState(() {
        nomeUsuario = nome;
        pessoas = lista;
        carregando = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => carregando = false);
      mostrarMensagem('Erro ao carregar os contatos.');
    }
  }

  void mostrarMensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> abrirFormulario({Map<String, Object?>? pessoa}) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PessoaFormScreen(usuarioId: widget.usuarioId, pessoa: pessoa),
      ),
    );

    if (resultado == true && mounted) {
      await carregarDados();

      if (!mounted) return;

      mostrarMensagem(
        pessoa == null
            ? 'Pessoa cadastrada com sucesso!'
            : 'Pessoa atualizada com sucesso!',
      );
    }
  }

  Future<bool> confirmarExclusao(Map<String, Object?> pessoa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir pessoa'),
        content: Text('Deseja excluir ${pessoa['nome']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    return confirmar == true;
  }

  Future<void> excluirPessoa(Map<String, Object?> pessoa) async {
    final confirmar = await confirmarExclusao(pessoa);

    if (!confirmar) return;

    try {
      await DatabaseHelper.instance.excluirPessoa(
        pessoa['id'] as int,
        widget.usuarioId,
      );

      if (!mounted) return;

      await carregarDados();

      if (mounted) {
        mostrarMensagem('Pessoa excluída com sucesso.');
      }
    } catch (_) {
      if (mounted) {
        mostrarMensagem('Não foi possível excluir a pessoa.');
      }
    }
  }

  Future<void> sair() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove('nomeUsuario');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas pessoas'),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: sair,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: carregarDados,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Olá, $nomeUsuario!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text('Seus contatos estão aqui.'),
                  const SizedBox(height: 20),
                  if (pessoas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 72,
                            color: Colors.indigo,
                          ),
                          SizedBox(height: 12),
                          Text('Nenhuma pessoa cadastrada.'),
                          Text('Use o botão abaixo para adicionar.'),
                        ],
                      ),
                    ),
                  ...pessoas.map((pessoa) {
                    final id = pessoa['id'] as int;
                    final nome = pessoa['nome'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await excluirPessoa(pessoa);
                          return false;
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                nome.isEmpty
                                    ? '?'
                                    : nome.substring(0, 1).toUpperCase(),
                              ),
                            ),
                            title: Text(nome),
                            subtitle: Text(
                              '${pessoa['email']}\n'
                              '${pessoa['telefone']}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => abrirFormulario(pessoa: pessoa),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormulario(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Adicionar'),
      ),
    );
  }
}
