import 'package:hive_flutter/hive_flutter.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const String _usuariosBoxName = 'usuarios';
  static const String _pessoasBoxName = 'pessoas';

  Box<Map>? _usuariosBox;
  Box<Map>? _pessoasBox;

  bool _inicializado = false;
  Future<void>? _inicializando;

  Future<void> _inicializar() async {
    if (_inicializado) return;

    // Evita inicializações simultâneas.
    if (_inicializando != null) {
      await _inicializando;
      return;
    }

    final inicializacao = _abrirCaixas();
    _inicializando = inicializacao;

    try {
      await inicializacao;
      _inicializado = true;
    } finally {
      _inicializando = null;
    }
  }

  Future<void> _abrirCaixas() async {
    await Hive.initFlutter();

    _usuariosBox = await Hive.openBox<Map>(_usuariosBoxName);
    _pessoasBox = await Hive.openBox<Map>(_pessoasBoxName);
  }

  Future<Box<Map>> get _usuarios async {
    await _inicializar();
    return _usuariosBox!;
  }

  Future<Box<Map>> get _pessoas async {
    await _inicializar();
    return _pessoasBox!;
  }

  Map<String, Object?> _converter(Map registro) {
    return Map<String, Object?>.from(registro);
  }

  int _proximoId(Box<Map> box) {
    if (box.isEmpty) return 1;

    final ids = box.keys.whereType<int>();
    if (ids.isEmpty) return 1;

    return ids.reduce((a, b) => a > b ? a : b) + 1;
  }

  // CADASTRAR USUÁRIO
  Future<int> cadastrarUsuario(String nome, String email, String senha) async {
    final box = await _usuarios;

    final nomeLimpo = nome.trim();
    final emailLimpo = email.trim().toLowerCase();

    if (nomeLimpo.isEmpty || emailLimpo.isEmpty || senha.isEmpty) {
      throw Exception('PREENCHA_TODOS_OS_CAMPOS');
    }

    final existentes = box.values.any(
      (usuario) =>
          (usuario['email'] as String? ?? '').toLowerCase() == emailLimpo,
    );

    if (existentes) {
      throw Exception('EMAIL_DUPLICADO');
    }

    final id = _proximoId(box);

    await box.put(id, {
      'id': id,
      'nome': nomeLimpo,
      'email': emailLimpo,
      'senha': senha,
    });

    return id;
  }

  // LOGIN
  Future<Map<String, Object?>?> login(String email, String senha) async {
    final box = await _usuarios;

    final emailLimpo = email.trim().toLowerCase();

    for (final usuario in box.values) {
      final emailSalvo = (usuario['email'] as String? ?? '').toLowerCase();

      if (emailSalvo == emailLimpo && usuario['senha'] == senha) {
        return _converter(usuario);
      }
    }

    return null;
  }

  // LISTAR PESSOAS DO USUÁRIO LOGADO
  Future<List<Map<String, Object?>>> listarPessoas(int usuarioId) async {
    final box = await _pessoas;

    final resultado = box.values
        .where((pessoa) => pessoa['usuario_id'] == usuarioId)
        .map(_converter)
        .toList();

    resultado.sort(
      (a, b) => (a['nome'] as String).toLowerCase().compareTo(
        (b['nome'] as String).toLowerCase(),
      ),
    );

    return resultado;
  }

  // CADASTRAR PESSOA
  Future<int> inserirPessoa(
    int usuarioId,
    String nome,
    String email,
    String telefone,
  ) async {
    final usuariosBox = await _usuarios;

    if (!usuariosBox.containsKey(usuarioId)) {
      throw Exception('USUARIO_NAO_ENCONTRADO');
    }

    final box = await _pessoas;
    final id = _proximoId(box);

    await box.put(id, {
      'id': id,
      'usuario_id': usuarioId,
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
    });

    return id;
  }

  // ATUALIZAR PESSOA
  Future<int> atualizarPessoa(
    int id,
    int usuarioId,
    String nome,
    String email,
    String telefone,
  ) async {
    final box = await _pessoas;
    final registro = box.get(id);

    if (registro == null || registro['usuario_id'] != usuarioId) {
      return 0;
    }

    await box.put(id, {
      ..._converter(registro),
      'nome': nome.trim(),
      'email': email.trim(),
      'telefone': telefone.trim(),
    });

    return 1;
  }

  // EXCLUIR PESSOA
  Future<int> excluirPessoa(int id, int usuarioId) async {
    final box = await _pessoas;
    final registro = box.get(id);

    if (registro == null || registro['usuario_id'] != usuarioId) {
      return 0;
    }

    await box.delete(id);
    return 1;
  }

  // EXCLUIR USUÁRIO E SUAS PESSOAS
  Future<int> excluirUsuario(int usuarioId) async {
    final usuariosBox = await _usuarios;
    final pessoasBox = await _pessoas;

    if (!usuariosBox.containsKey(usuarioId)) {
      return 0;
    }

    final idsPessoas = pessoasBox.keys.where((key) {
      final pessoa = pessoasBox.get(key);
      return pessoa?['usuario_id'] == usuarioId;
    }).toList();

    await pessoasBox.deleteAll(idsPessoas);
    await usuariosBox.delete(usuarioId);

    return 1;
  }
}
