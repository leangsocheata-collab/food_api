import 'package:dart_frog/dart_frog.dart';
import 'package:dbcrypt/dbcrypt.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) return notAllowed();
  final b = await readBody(context);
  final name = (b['name'] ?? '').toString().trim();
  final email = (b['email'] ?? '').toString().trim().toLowerCase();
  final phone = (b['phone'] ?? '').toString().trim();
  final password = (b['password'] ?? '').toString();
  if (name.isEmpty) return fail('name is required');
  if (email.isEmpty && phone.isEmpty) return fail('email or phone is required');
  if (password.length < 6) return fail('password must be at least 6 characters');

  final users = await Database.users;
  final or = <Map<String, dynamic>>[
    if (email.isNotEmpty) {'email': email},
    if (phone.isNotEmpty) {'phone': phone},
  ];
  if (await users.findOne({r'$or': or}) != null) return fail('Account already exists', status: 409);

  final id = ObjectId();
  final user = {
    '_id': id,
    'name': name,
    'email': email.isEmpty ? null : email,
    'phone': phone.isEmpty ? null : phone,
    'passwordHash': DBCrypt().hashpw(password, DBCrypt().gensalt()),
    'role': 'user',
    'walletBalance': 0.0,
    'createdAt': now(),
  };
  await users.insertOne(user);
  return ok({'token': signToken(id, 'user'), 'user': user}, message: 'Registered', status: 201);
}
