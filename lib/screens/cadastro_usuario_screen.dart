import 'package:flutter/material.dart';

import '../database/database_helper.dart';

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;
  bool mostrarSenha = false;

  void mostrarMensagem(String texto) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(texto), duration: const Duration(seconds: 5)),
      );
  }

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> cadastrar() async {
    if (carregando) return;

    final nome = nomeController.text.trim();
    final email = emailController.text.trim().toLowerCase();
    final senha = senhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      mostrarMensagem('Preencha todos os campos.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      mostrarMensagem('Informe um e-mail válido.');
      return;
    }

    if (senha.length < 4) {
      mostrarMensagem('A senha deve ter pelo menos 4 caracteres.');
      return;
    }

    setState(() => carregando = true);

    try {
      final id = await DatabaseHelper.instance.cadastrarUsuario(
        nome,
        email,
        senha,
      );

      debugPrint('Usuário cadastrado com sucesso. ID: $id');

      if (!mounted) return;

      mostrarMensagem('Usuário cadastrado com sucesso!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro, stackTrace) {
      debugPrint('========== ERRO NO CADASTRO ==========');
      debugPrint('Tipo: ${erro.runtimeType}');
      debugPrint('Detalhes: $erro');
      debugPrintStack(stackTrace: stackTrace);
      debugPrint('======================================');

      if (!mounted) return;

      final erroTexto = erro.toString().toLowerCase();

      String mensagem;

      if (erroTexto.contains('email_duplicado') ||
          erroTexto.contains('unique constraint failed')) {
        mensagem = 'Este e-mail já está cadastrado. Utilize outro.';
      } else if (erroTexto.contains('no such table')) {
        mensagem = 'A tabela de usuários não existe no banco de dados.';
      } else if (erroTexto.contains('no column named')) {
        mensagem = 'A estrutura do banco está diferente da esperada.';
      } else if (erroTexto.contains('preencha_todos_os_campos')) {
        mensagem = 'Preencha todos os campos.';
      } else {
        mensagem = 'Erro ao cadastrar: $erro';
      }

      mostrarMensagem(mensagem);
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de usuário')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.person_add_alt_1,
                    size: 76,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Criar conta',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Preencha os dados para começar.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: nomeController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      hintText: 'seuemail@exemplo.com',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: senhaController,
                    obscureText: !mostrarSenha,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => cadastrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: mostrarSenha
                            ? 'Ocultar senha'
                            : 'Mostrar senha',
                        onPressed: () {
                          setState(() {
                            mostrarSenha = !mostrarSenha;
                          });
                        },
                        icon: Icon(
                          mostrarSenha
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: carregando ? null : cadastrar,
                      child: carregando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Cadastrar usuário'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: carregando ? null : () => Navigator.pop(context),
                    child: const Text('Voltar para o login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
