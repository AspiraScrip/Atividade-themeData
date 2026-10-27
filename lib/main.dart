import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';

import 'database/database_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GerenciadorApp());
}

final db = DatabaseHelper.instance;

class GerenciadorApp extends StatelessWidget {
  const GerenciadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gerenciador de Pessoas',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const LoginScreen(),
    );
  }
}

void mensagem(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final senha = TextEditingController();
  bool carregando = false;

  @override
  void dispose() {
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    if (email.text.trim().isEmpty || senha.text.isEmpty) {
      mensagem(context, 'Informe o e-mail e a senha.');
      return;
    }

    setState(() => carregando = true);

    try {
      final usuario = await db.login(email.text, senha.text);

      if (!mounted) return;

      if (usuario == null) {
        mensagem(context, 'E-mail ou senha inválidos.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nomeUsuario', usuario['nome'] as String);
      await prefs.setInt('usuarioId', usuario['id'] as int);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(usuarioId: usuario['id'] as int),
        ),
      );
    } catch (_) {
      if (mounted) {
        mensagem(context, 'Não foi possível realizar o login.');
      }
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.people_alt_rounded,
                size: 76,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              Text(
                'Gerenciador de Pessoas',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: senha,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                onSubmitted: (_) => entrar(),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: carregando ? null : entrar,
                  child: Text(carregando ? 'Entrando...' : 'Entrar'),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CadastroUsuarioScreen(),
                  ),
                ),
                child: const Text('Cadastrar novo usuário'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CadastroUsuarioScreen extends StatefulWidget {
  const CadastroUsuarioScreen({super.key});

  @override
  State<CadastroUsuarioScreen> createState() => _CadastroUsuarioScreenState();
}

class _CadastroUsuarioScreenState extends State<CadastroUsuarioScreen> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final senha = TextEditingController();
  bool salvando = false;

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    senha.dispose();
    super.dispose();
  }

  Future<void> cadastrar() async {
    if (salvando) return;

    final nomeUsuario = nome.text.trim();
    final emailUsuario = email.text.trim().toLowerCase();
    final senhaUsuario = senha.text;

    if (nomeUsuario.isEmpty ||
        emailUsuario.isEmpty ||
        senhaUsuario.length < 4) {
      mensagem(
        context,
        'Preencha os campos. A senha deve ter ao menos 4 caracteres.',
      );
      return;
    }

    setState(() => salvando = true);

    try {
      final id = await db.cadastrarUsuario(
        nomeUsuario,
        emailUsuario,
        senhaUsuario,
      );

      debugPrint('Usuário cadastrado com ID: $id');

      if (!mounted) return;

      mensagem(context, 'Usuário cadastrado com sucesso!');
      Navigator.pop(context);
    } catch (erro, stackTrace) {
      debugPrint('ERRO NO CADASTRO: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final detalhe = erro.toString().toLowerCase();

      if (detalhe.contains('unique constraint failed') ||
          detalhe.contains('usuarios.email')) {
        mensagem(context, 'Este e-mail já está cadastrado.');
      } else {
        mensagem(context, 'Erro ao cadastrar. Veja os detalhes no terminal.');
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
      appBar: AppBar(title: const Text('Novo usuário')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome completo'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: senha,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Senha'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: salvando ? null : cadastrar,
            child: Text(salvando ? 'Salvando...' : 'Cadastrar usuário'),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final int usuarioId;

  const HomeScreen({super.key, required this.usuarioId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, Object?>> pessoas = [];
  String nomeUsuario = '';
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final lista = await db.listarPessoas(widget.usuarioId);

    if (!mounted) return;

    setState(() {
      nomeUsuario = prefs.getString('nomeUsuario') ?? 'Usuário';
      pessoas = lista;
      carregando = false;
    });
  }

  Future<void> abrirFormulario([Map<String, Object?>? pessoa]) async {
    final resultado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PessoaFormScreen(usuarioId: widget.usuarioId, pessoa: pessoa),
      ),
    );

    if (resultado == true) {
      await carregar();
      if (mounted) {
        mensagem(
          context,
          pessoa == null
              ? 'Pessoa cadastrada com sucesso!'
              : 'Pessoa atualizada com sucesso!',
        );
      }
    }
  }

  Future<void> excluir(Map<String, Object?> pessoa) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir pessoa?'),
        content: Text('Deseja excluir ${pessoa['nome']} permanentemente?'),
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

    if (confirmar != true) return;

    await db.excluirPessoa(pessoa['id'] as int, widget.usuarioId);

    if (!mounted) return;
    await carregar();

    if (mounted) mensagem(context, 'Pessoa excluída com sucesso.');
  }

  Future<void> sair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('nomeUsuario');
    await prefs.remove('usuarioId');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
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
              onRefresh: carregar,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Olá, $nomeUsuario!',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text('Gerencie seus contatos abaixo.'),
                  const SizedBox(height: 24),
                  if (pessoas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Icon(
                            Icons.contacts_outlined,
                            size: 64,
                            color: Colors.indigo,
                          ),
                          SizedBox(height: 12),
                          Text('Nenhuma pessoa cadastrada.'),
                          Text('Toque no botão + para começar.'),
                        ],
                      ),
                    ),
                  ...pessoas.map((pessoa) {
                    final id = pessoa['id'] as int;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: ValueKey(id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        confirmDismiss: (_) async {
                          await excluir(pessoa);
                          return false;
                        },
                        child: Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                (pessoa['nome'] as String)
                                    .substring(0, 1)
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(pessoa['nome'] as String),
                            subtitle: Text(
                              '${pessoa['email']}\n${pessoa['telefone']}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.edit_outlined),
                            onTap: () => abrirFormulario(pessoa),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Adicionar'),
      ),
    );
  }
}

class PessoaFormScreen extends StatefulWidget {
  final int usuarioId;
  final Map<String, Object?>? pessoa;

  const PessoaFormScreen({super.key, required this.usuarioId, this.pessoa});

  @override
  State<PessoaFormScreen> createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends State<PessoaFormScreen> {
  final nome = TextEditingController();
  final email = TextEditingController();
  final telefone = TextEditingController();
  bool salvando = false;

  bool get editando => widget.pessoa != null;

  @override
  void initState() {
    super.initState();

    final pessoa = widget.pessoa;
    if (pessoa != null) {
      nome.text = pessoa['nome'] as String;
      email.text = pessoa['email'] as String;
      telefone.text = pessoa['telefone'] as String;
    }
  }

  @override
  void dispose() {
    nome.dispose();
    email.dispose();
    telefone.dispose();
    super.dispose();
  }

  Future<void> salvar() async {
    if (nome.text.trim().isEmpty ||
        email.text.trim().isEmpty ||
        telefone.text.trim().isEmpty) {
      mensagem(context, 'Preencha todos os campos.');
      return;
    }

    setState(() => salvando = true);

    try {
      if (editando) {
        await db.atualizarPessoa(
          widget.pessoa!['id'] as int,
          widget.usuarioId,
          nome.text,
          email.text,
          telefone.text,
        );
      } else {
        await db.inserirPessoa(
          widget.usuarioId,
          nome.text,
          email.text,
          telefone.text,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        mensagem(context, 'Erro ao salvar os dados da pessoa.');
      }
    } finally {
      if (mounted) setState(() => salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(editando ? 'Editar pessoa' : 'Nova pessoa')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: nome,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: telefone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Telefone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: salvando ? null : salvar,
            icon: const Icon(Icons.save_outlined),
            label: Text(salvando ? 'Salvando...' : 'Salvar'),
          ),
        ],
      ),
    );
  }
}
