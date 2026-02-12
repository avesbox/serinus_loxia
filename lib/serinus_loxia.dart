import 'package:serinus/serinus.dart';
import 'package:loxia/loxia.dart';

/// A module that integrates Loxia with Serinus, allowing you to use Loxia's repositories and data sources within your Serinus application.
class LoxiaModule extends Module {
  /// The data source options used to configure the Loxia data source.
  final DataSourceOptions _options;

  LoxiaModule._(this._options);

  /// Creates a LoxiaModule with an in-memory data source, using the provided entity descriptors.
  factory LoxiaModule.inMemory({required List<EntityDescriptor> entities}) {
    return LoxiaModule._(InMemoryDataSourceOptions(entities: entities));
  }

  /// Creates a LoxiaModule with a SQLite data source, using the provided path, entity descriptors, and optional migrations.
  factory LoxiaModule.sqlite({
    required String path,
    required List<EntityDescriptor> entities,
    List<Migration>? migrations,
  }) {
    return LoxiaModule._(
      SqliteDataSourceOptions(
        path: path,
        entities: entities,
        migrations: migrations ?? [],
      ),
    );
  }

  /// Creates a LoxiaModule with a PostgreSQL data source, using the provided connection details, entity descriptors, and optional migrations.
  factory LoxiaModule.postgres({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
    required List<EntityDescriptor> entities,
    ConnectionSettings? settings,
    List<Migration>? migrations,
  }) {
    return LoxiaModule._(
      PostgresDataSourceOptions.connect(
        host: host,
        port: port,
        database: database,
        username: username,
        password: password,
        entities: entities,
        migrations: migrations ?? [],
        settings: settings,
      ),
    );
  }

  /// Registers a feature module exposing repositories for the given entities.
  static LoxiaFeatureModule features({required List<Type> entities}) {
    return LoxiaFeatureModule(entities);
  }

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final ds = DataSource(_options);
    await ds.init();
    _GlobalRepositoriesRegistry.set(ds.repositories);
    return DynamicModule(providers: [], exports: []);
  }
}

/// A module that exposes repositories for the specified entities, allowing you to inject them into your controllers and services.
class LoxiaFeatureModule extends Module {
  /// The list of entity types for which repositories should be exposed.
  final List<Type> _entities;

  /// Creates a LoxiaFeatureModule that exposes repositories for the specified entities.
  LoxiaFeatureModule(this._entities);

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final providers = <Provider>[];
    final exports = <Type>[];
    for (final entityType in _entities) {
      final repository = _GlobalRepositoriesRegistry.get(entityType);
      if (repository != null) {
        providers.add(
          Provider.forValue(repository, asType: repository.runtimeType),
        );
        exports.add(repository.runtimeType);
      }
    }
    return DynamicModule(providers: providers, exports: exports);
  }
}

class _GlobalRepositoriesRegistry {
  static final Map<Type, EntityRepository> _repositories = {};

  static void set(Map<Type, EntityRepository> repositories) {
    _repositories.addAll(repositories);
  }

  static EntityRepository? get(Type entityType) {
    return _repositories[entityType];
  }
}
