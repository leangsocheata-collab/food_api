import 'package:dart_frog/dart_frog.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return notAllowed();
  final b = await readBody(context);
  final id = (b['identifier'] ?? b['email'] ?? b['phone'] ?? '').toString().trim().toLowerCase();
  final password = (b['password'] ?? '').toString();
  if (id.isEmpty || password.isEmpty) return fail('identifier and password are required');

  final users = await Database.users;
  final user = await users.findOne({
    r'$or': [
      {'email': id},
      {'phone': id},
    ]
  });
  if (user == null || !DBCrypt().checkpw(password, user['passwordHash'] as String)) {
    return fail('Invalid credentials', status: 401);
  }
  return ok({'token': signToken(user['_id'] as ObjectId, user['role'] as String), 'user': user},
      message: 'Logged in');
}
