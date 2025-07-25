// Importações necessárias para manipular caminhos, banco de dados e controle de concorrência
import 'package:path/path.dart'; // Para unir caminhos de forma segura entre plataformas
import 'package:sqflite/sqflite.dart'; // Biblioteca principal do SQLite no Flutter
import 'package:synchronized/synchronized.dart'; // Para garantir que só uma thread acesse o banco ao mesmo tempo

class SqliteConnectionFactory {
  // Versão do banco (use para upgrades futuros)
  static const _VERSION = 1;

  // Nome do arquivo do banco de dados
  static const _DATABASE_NAME = 'TODO_LIST_PROVIDER.db';

  // Referência interna para a conexão com o banco (pode ser null no início)
  Database? _db;

  // Lock usado para evitar concorrência (duas chamadas tentando abrir o banco ao mesmo tempo)
  final _lock = Lock();

  // Instância única da classe (padrão Singleton)
  static SqliteConnectionFactory? _instance;

  // Construtor privado → ninguém fora da classe pode criar uma instância diretamente
  SqliteConnectionFactory._();

  // Construtor factory → garante que só existe uma instância da classe
  factory SqliteConnectionFactory() {
    _instance ??= SqliteConnectionFactory._(); // Se _instance for null, cria
    return _instance!; // Retorna a instância existente
  }

  /// Abre a conexão com o banco de dados
  /// Se já estiver aberta, apenas retorna
  /// Se for a primeira vez, inicializa usando lock para garantir segurança
  Future<Database> openConnection() async {
    // Obtém o caminho onde o banco será salvo no dispositivo
    var databasePath = await getDatabasesPath();

    // Junta o caminho com o nome do banco
    var dataBasePathFinal = join(databasePath, _DATABASE_NAME);

    // Se ainda não existe uma conexão
    if (_db == null) {
      // Entra em uma região sincronizada para evitar múltiplas aberturas simultâneas
      await _lock.synchronized(() async {
        // Verifica novamente se o banco ainda não foi aberto (evita condição de corrida)
        if (_db == null) {
          _db = await openDatabase(
            dataBasePathFinal, // Caminho completo do banco
            version: _VERSION, // Versão do banco (ajuda em upgrades)
            onConfigure: _onConfigure, // Ativa chaves estrangeiras
            onCreate: _onCreate, // Cria as tabelas na primeira vez
            onUpgrade: _onUpgrade, // Atualiza o banco se a versão for maior
            onDowngrade: _onDowngrade, // Trata downgrade de versão (opcional)
          );
        }
      });
    }

    // Retorna a instância do banco já conectada
    return _db!;
  }

  /// Fecha a conexão com o banco de dados.
  /// Pode ser chamado ao encerrar o app ou sair de uma funcionalidade.
  void closeConnection() {
    _db?.close(); // Fecha a conexão se existir
    _db = null; // Limpa a referência interna
  }

  /// Ativado antes de abrir o banco → aqui ativamos chaves estrangeiras (boa prática)
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Chamado quando o banco for criado pela primeira vez
  /// Ideal para criar tabelas
  Future<void> _onCreate(Database db, int version) async {
    // Exemplo: crie suas tabelas aqui
    // await db.execute('CREATE TABLE ...');
  }

  /// Chamado quando o banco for atualizado para uma nova versão
  /// Use para adicionar colunas ou novas tabelas sem apagar os dados
  Future<void> _onUpgrade(Database db, int oldVersion, int version) async {
    // if (oldVersion < 2) { ... }
  }

  /// Chamado se o banco voltar para uma versão anterior
  /// Pode ser útil em testes ou rollback
  Future<void> _onDowngrade(Database db, int oldVersion, int version) async {
    // Use com cuidado. Geralmente evita-se essa operação.
  }
}
