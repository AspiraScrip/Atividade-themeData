
# Gerenciador de Pessoas

Aplicativo mobile desenvolvido em Flutter para gerenciamento
de usuários e contatos, com armazenamento local.

## Tecnologias

- Flutter e Dart
- SQLite com sqflite
- SharedPreferences
- Material Design 3

## Funcionalidades

- Cadastro de usuários
- Login com e-mail e senha
- Sessão com nome do usuário
- Cadastro, consulta, edição e exclusão de pessoas
- Lista de contatos privada por usuário
- Exclusão com gesto de deslizar
- Mensagens de feedback usando SnackBar
- Confirmação antes da exclusão

## Estrutura do banco

### usuarios

- id
- nome
- email
- senha

### pessoas

- id
- usuario_id
- nome
- email
- telefone

## Como executar

1. Instale o Flutter e configure o Android SDK.
2. Abra o projeto no VS Code ou Android Studio.
3. Execute `flutter pub get`.
4. Inicie um emulador ou conecte um celular.
5. Execute `flutter run`.

## Teste do aplicativo

1. Cadastre um usuário.
2. Faça login.
3. Cadastre uma pessoa.
4. Toque na pessoa para editar.
5. Deslize a pessoa para excluir.
6. Confirme que o registro foi removido.
7. Saia e faça login novamente.

## Observação

Este projeto é acadêmico e utiliza autenticação local.
Para uso em produção, implemente armazenamento seguro
de senhas e controles de segurança adicionais.
