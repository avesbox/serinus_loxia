import 'package:loxia/loxia.dart';
import 'package:serinus/serinus.dart';
import 'package:serinus_loxia/serinus_loxia.dart';
part 'serinus_loxia.g.dart';

@EntityMeta()
class User extends Entity {
  @PrimaryKey(autoIncrement: true)
  final int id;

  @Column()
  final String name;

  const User({required this.id, required this.name});

  static final entity = $UserEntityDescriptor;
}

class UserController extends Controller {
  UserController() : super('/') {
    on(Route.get('/'), (context) async {
      final repo = context.use<UserRepository>();
      final users = await repo.paginate(
        page: context.query['page'] != null
            ? int.tryParse(context.query['page']!) ?? 1
            : 1,
        pageSize: context.query['pageSize'] != null
            ? int.tryParse(context.query['pageSize']!) ?? 10
            : 10,
      );
      final usersFull = await repo.findBy();
      return {
        'users': users.items,
        'total': users.total,
        'page': users.page,
        'pageSize': users.pageSize,
        'usersFull': usersFull.map((e) => e.toJson()).toList(),
      };
    });
    on(Route.post('/'), (RequestContext<Map<String, dynamic>> context) async {
      final repo = context.use<UserRepository>();
      final data = context.body;
      if (data['name'] == null) {
        throw BadRequestException('Missing name');
      }
      final column = await repo.insert(UserInsertDto(name: data['name']));
      return column;
    });
  }
}

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

Future<void> main() async {
  final app = await serinus.createApplication(entrypoint: AppModule());
  await app.serve();
}
