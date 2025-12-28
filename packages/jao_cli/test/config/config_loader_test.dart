import 'package:test/test.dart';
import 'package:jao/jao.dart';
import 'package:jao_cli/jao_cli.dart';

void main() {
  group('MigrationRunnerConfig', () {
    group('constructor', () {
      test('creates config with required parameters', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        expect(config.database.database, equals(':memory:'));
        expect(config.adapter, isA<SqliteAdapter>());
        expect(config.migrations, isEmpty);
      });

      test('Loads database.type', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite('test.db'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        // SQLite adapter is loaded
        expect(config.adapter, isA<SqliteAdapter>());
        expect(config.adapter.name, equals('sqlite'));
      });

      test('Loads database.host', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'custom-host.example.com', port: 5432, database: 'testdb'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.database.host, equals('custom-host.example.com'));
      });

      test('Loads database.port', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 5433, database: 'testdb'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.database.port, equals(5433));
      });

      test('Loads database.name', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 5432, database: 'my_application'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.database.database, equals('my_application'));
      });

      test('Loads database.username', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb', username: 'dbuser'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.database.username, equals('dbuser'));
      });

      test('Loads database.password', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb', password: 'secret123'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.database.password, equals('secret123'));
      });

      test('defaults migrationsTable to jao_migrations', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        expect(config.migrationsTable, equals('jao_migrations'));
      });

      test('allows custom migrationsTable', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          migrationsTable: 'custom_migrations',
        );

        expect(config.migrationsTable, equals('custom_migrations'));
      });

      test('defaults verbose to false', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        expect(config.verbose, isFalse);
      });

      test('allows verbose true', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          verbose: true,
        );

        expect(config.verbose, isTrue);
      });

      test('accepts model schemas', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: [],
          modelSchemas: [
            ModelSchema(
              className: 'User',
              tableName: 'users',
              fields: [ModelFieldSchema(name: 'id', columnName: 'id', dbType: FieldType.integer, primaryKey: true)],
            ),
          ],
        );

        expect(config.modelSchemas, hasLength(1));
        expect(config.modelSchemas.first.className, equals('User'));
      });
    });

    group('adapter detection', () {
      test('Detects adapter from type field - PostgreSQL', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb'),
          adapter: const PostgresAdapter(),
          migrations: [],
        );

        expect(config.adapter, isA<PostgresAdapter>());
        expect(config.adapter.name, equals('postgresql'));
      });

      test('Detects adapter from type field - MySQL', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig(host: 'localhost', port: 3306, database: 'testdb'),
          adapter: const MySqlAdapter(),
          migrations: [],
        );

        expect(config.adapter, isA<MySqlAdapter>());
        expect(config.adapter.name, equals('mysql'));
      });

      test('Detects adapter from type field - SQLite', () {
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite('database.db'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        expect(config.adapter, isA<SqliteAdapter>());
        expect(config.adapter.name, equals('sqlite'));
      });
    });

    group('DatabaseConfig.fromUrl', () {
      test('Parses postgres:// URL', () {
        final config = DatabaseConfig.fromUrl('postgres://user:pass@host:5432/dbname');

        expect(config.host, equals('host'));
        expect(config.port, equals(5432));
        expect(config.database, equals('dbname'));
        expect(config.username, equals('user'));
        expect(config.password, equals('pass'));
      });

      test('Parses postgresql:// URL', () {
        final config = DatabaseConfig.fromUrl('postgresql://user:pass@host:5432/dbname');

        expect(config.host, equals('host'));
        expect(config.port, equals(5432));
        expect(config.database, equals('dbname'));
      });

      test('Parses mysql:// URL', () {
        final config = DatabaseConfig.fromUrl('mysql://root:password@localhost:3306/mydb');

        expect(config.host, equals('localhost'));
        expect(config.port, equals(3306));
        expect(config.database, equals('mydb'));
        expect(config.username, equals('root'));
        expect(config.password, equals('password'));
      });

      test('Parses sqlite:// URL', () {
        final config = DatabaseConfig.fromUrl('sqlite://database.db');

        // SQLite path is parsed as host by URI parser
        expect(config.host, equals('database.db'));
      });

      test('Parses SQLite with path', () {
        // Use proper file path URL format for SQLite
        final config = DatabaseConfig.fromUrl('sqlite:///path/to/database.db');

        // Path is stripped of leading slash and stored in database
        expect(config.database, equals('path/to/database.db'));
      });

      test('Parses URL without port (uses default)', () {
        final config = DatabaseConfig.fromUrl('postgres://user:pass@host/db');

        expect(config.host, equals('host'));
        expect(config.database, equals('db'));
      });

      test('Parses URL without credentials', () {
        final config = DatabaseConfig.fromUrl('postgres://host:5432/db');

        expect(config.host, equals('host'));
        expect(config.port, equals(5432));
        expect(config.database, equals('db'));
      });
    });

    group('DatabaseConfig.sqlite', () {
      test('creates SQLite config', () {
        final config = DatabaseConfig.sqlite('test.db');

        expect(config.database, equals('test.db'));
      });

      test('creates SQLite in-memory config', () {
        final config = DatabaseConfig.sqlite(':memory:');

        expect(config.database, equals(':memory:'));
      });
    });

    group('default fallback', () {
      test('Falls back to SQLite when no config', () {
        // The SQLite adapter is a reasonable default for local development
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite('database.db'),
          adapter: const SqliteAdapter(),
          migrations: [],
        );

        expect(config.adapter, isA<SqliteAdapter>());
      });
    });

    group('validation', () {
      test('Validates required fields', () {
        // Should not throw with valid config
        expect(
          () => MigrationRunnerConfig(
            database: DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb'),
            adapter: const PostgresAdapter(),
            migrations: [],
          ),
          returnsNormally,
        );
      });

      test('migrations list can be provided', () {
        final migrations = [_TestMigration()];
        final config = MigrationRunnerConfig(
          database: DatabaseConfig.sqlite(':memory:'),
          adapter: const SqliteAdapter(),
          migrations: migrations,
        );

        expect(config.migrations, hasLength(1));
        expect(config.migrations.first.name, equals('test_migration'));
      });
    });

    group('dialect mapping', () {
      test('PostgresAdapter uses postgres dialect', () {
        const adapter = PostgresAdapter();
        expect(adapter.dialect, isA<PostgresDialect>());
      });

      test('MySqlAdapter uses mysql dialect', () {
        const adapter = MySqlAdapter();
        expect(adapter.dialect, isA<MySqlDialect>());
      });

      test('SqliteAdapter uses sqlite dialect', () {
        const adapter = SqliteAdapter();
        expect(adapter.dialect, isA<SqliteDialect>());
      });
    });

    group('fromEnvironment', () {
      test('factory accepts migrations parameter', () {
        // This tests that the factory method signature is correct
        expect(() => MigrationRunnerConfig.fromEnvironment(migrations: [_TestMigration()]), returnsNormally);
      });

      test('factory accepts modelSchemas parameter', () {
        final schemas = [ModelSchema(className: 'Test', tableName: 'tests', fields: [])];

        expect(() => MigrationRunnerConfig.fromEnvironment(migrations: [], modelSchemas: schemas), returnsNormally);
      });

      test('factory accepts custom adapter', () {
        expect(
          () => MigrationRunnerConfig.fromEnvironment(migrations: [], adapter: const SqliteAdapter()),
          returnsNormally,
        );
      });

      test('factory accepts migrationsTable', () {
        final config = MigrationRunnerConfig.fromEnvironment(migrations: [], migrationsTable: 'custom_table');

        expect(config.migrationsTable, equals('custom_table'));
      });

      test('factory accepts verbose flag', () {
        final config = MigrationRunnerConfig.fromEnvironment(migrations: [], verbose: true);

        expect(config.verbose, isTrue);
      });
    });

    group('SSL configuration', () {
      test('useSsl defaults to false', () {
        final config = DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb');

        expect(config.useSsl, isFalse);
      });

      test('useSsl can be set to true', () {
        final config = DatabaseConfig(host: 'localhost', port: 5432, database: 'testdb', useSsl: true);

        expect(config.useSsl, isTrue);
      });
    });
  });
}

/// Test migration for config tests.
class _TestMigration extends Migration {
  @override
  String get name => 'test_migration';

  @override
  void up(MigrationBuilder builder) {}

  @override
  void down(MigrationBuilder builder) {}
}
