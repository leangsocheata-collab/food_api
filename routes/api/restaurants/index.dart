import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;

/// GET = list restaurants, POST = create (admin)
Future<Response> onRequest(RequestContext context) async {
  final col = await Database.restaurants;
  switch (context.request.method) {
    case HttpMethod.get:
      return ok(await col.find(where.sortBy('rating', descending: true)).toList());
    case HttpMethod.post:
      final me = currentUser(context);
      if (me == null) return unauthorized();
      if (!me.isAdmin) return forbidden();
      final b = await readBody(context);
      if ((b['name'] ?? '').toString().isEmpty) return fail('name is required');
      final doc = {
        '_id': ObjectId(),
        'name': b['name'],
        'cuisine': b['cuisine'],
        'address': b['address'],
        'rating': toDouble(b['rating']) ?? 0.0,
        'createdAt': now(),
      };
      await col.insertOne(doc);
      return ok(doc, status: 201);
    default:
      return notAllowed();
  }
}
