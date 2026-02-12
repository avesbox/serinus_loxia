# Serinus Loxia Integration

This package provides integration between Serinus and Loxia, allowing you to easily use Loxia as your database solution in your Serinus applications. With this integration, you can define your database models as Dart classes and leverage Loxia's powerful features for data management while benefiting from Serinus's modular architecture and dependency injection system.

## Getting Started

To get started with Serinus and Loxia, you can add the `serinus_loxia` and `loxia` packages to your project:

```bash
dart pub add serinus_loxia loxia
```

Then, you can define your database models as Dart classes and use them in your Serinus application. For example:

```dart
import 'package:loxia/loxia.dart';
part 'user.g.dart';
@EntityMeta()
class User extends Entity {
	@PrimaryKey(autoIncrement: true)
	final int id;

	@Column()
	final String name;

	const User({required this.id, required this.name});
	
	static final entity = $UserEntityDescriptor;
}
```

Next, you can add the `LoxiaModule` to your Serinus application to enable the integration:

```dart
import 'package:serinus/serinus.dart';
import 'package:serinus_loxia/serinus_loxia.dart';

class AppModule extends Module {
  AppModule()
	: super(
		imports: [
		  LoxiaModule.inMemory(entities: [User.entity]),
		  LoxiaModule.features(entities: [User]),
		],
		controllers: [UserController()],
	  );
}
```

With this setup, you have now registered the `User` model with Loxia and can use it in your Serinus application to perform database operations.