import 'package:serinus/serinus.dart';
import 'package:loxia/loxia.dart';

/// A module that integrates Loxia with Serinus, allowing you to use Loxia's repositories and data sources within your Serinus application.
class LoxiaModule extends Module {
  /// The data source options used to configure the Loxia data source.
  final DataSourceOptions _options;

  final String name;

  @override
  bool get isGlobal => true;

  @override
  String get token => name != 'default' ? 'LoxiaModule_$name' : 'LoxiaModule';

  static final Set<String> _registeredModuleNames = {};

  static Set<String> get registeredModuleNames => _registeredModuleNames;

  LoxiaModule._(this._options, {this.name = 'default'});

  /// Creates a LoxiaModule with an in-memory data source, using the provided entity descriptors.
  factory LoxiaModule.inMemory({
    required List<EntityDescriptor> entities,
    String name = 'default',
  }) {
    return LoxiaModule._(
      InMemoryDataSourceOptions(entities: entities),
      name: name,
    );
  }

  /// Creates a LoxiaModule with a SQLite data source, using the provided path, entity descriptors, and optional migrations.
  factory LoxiaModule.sqlite({
    required String path,
    required List<EntityDescriptor> entities,
    List<Migration>? migrations,
    String name = 'default',
  }) {
    return LoxiaModule._(
      SqliteDataSourceOptions(
        path: path,
        entities: entities,
        migrations: migrations ?? [],
      ),
      name: name,
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
    String name = 'default',
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
      name: name,
    );
  }

  /// Registers a feature module exposing repositories for the given entities.
  static LoxiaFeatureModule features({
    required List<Type> entities,
    String name = 'default',
  }) {
    return LoxiaFeatureModule(entities, name: name);
  }

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final ds = DataSource(_options);
    await ds.init();
    if (_registeredModuleNames.contains(name)) {
      throw Exception(
        'A LoxiaModule with the name "$name" has already been registered. Please choose a unique name for each LoxiaModule.',
      );
    }
    _registeredModuleNames.add(name);
    _GlobalRepositoriesRegistry.set(ds.repositories, name: name);
    return DynamicModule(
      providers: [
        Provider.forValue<DataSource>(
          ds,
          asType: DataSource,
          name: name != 'default' ? name : null,
        ),
      ],
      exports: [Export.value<DataSource>(name != 'default' ? name : null)],
    );
  }
}

/// A module that exposes repositories for the specified entities, allowing you to inject them into your controllers and services.
class LoxiaFeatureModule extends Module {
  /// The list of entity types for which repositories should be exposed.
  final List<Type> _entities;

  final String name;

  @override
  String get token =>
      name != 'default' ? 'LoxiaFeatureModule_$name' : 'LoxiaFeatureModule';

  /// Creates a LoxiaFeatureModule that exposes repositories for the specified entities.
  LoxiaFeatureModule(this._entities, {this.name = 'default'});

  @override
  Future<DynamicModule> registerAsync(ApplicationConfig config) async {
    final providers = <Provider>[];
    final exports = <Type>[];
    for (final entityType in _entities) {
      final repository = _GlobalRepositoriesRegistry.get(
        entityType,
        name: name,
      );
      if (repository != null) {
        providers.add(
          Provider.forValue(
            repository,
            asType: repository.runtimeType,
            name: name != 'default' ? name : null,
          ),
        );
        exports.add(
          Export(repository.runtimeType, name: name != 'default' ? name : null),
        );
      }
    }
    return DynamicModule(providers: providers, exports: exports);
  }
}

class _GlobalRepositoriesRegistry {
  static final Map<String, Map<Type, EntityRepository>> _repositories = {};

  static void set(
    Map<Type, EntityRepository> repositories, {
    String name = 'default',
  }) {
    _repositories[name] = repositories;
  }

  static EntityRepository? get(Type entityType, {String name = 'default'}) {
    return _repositories[name]?[entityType];
  }
}
