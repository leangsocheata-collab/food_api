import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId, where;

/// GET /api/foods?category=noodles&restaurantId=...&q=kuy   |   POST = create (admin)
Future<Response> onRequest(RequestContext context) async {
  final foods = await Database.foods;
  switch (context.request.method) {
    case HttpMethod.get:
      final q = context.request.uri.queryParameters;
      final s = where.ne('available', false);
      if ((q['category'] ?? '').isNotEmpty) s.eq('category', q['category']);
      final rid = toOid(q['restaurantId']);
      if (rid != null) s.eq('restaurantId', rid);
      if ((q['q'] ?? '').isNotEmpty) s.match('name', RegExp.escape(q['q']!), caseInsensitive: true);
      return ok(await foods.find(s.sortBy('createdAt', descending: true).limit(100)).toList());
    case HttpMethod.post:
      final me = currentUser(context);
      if (me == null) return unauthorized();
      if (!me.isAdmin) return forbidden();
      final b = await readBody(context);
      final price = toDouble(b['price']);
      if ((b['name'] ?? '').toString().isEmpty || price == null || price <= 0) {
        return fail('name and a positive price are required');
      }
      final doc = {
        '_id': ObjectId(),
        'name': b['name'],
        'description': b['description'] ?? '',
        'price': price,
        'category': b['category'],
        'restaurantId': toOid(b['restaurantId']?.toString()),
        'available': true,
        'createdAt': now(),
      };
      await foods.insertOne(doc);
      return ok(doc, status: 201);
    default:
      return notAllowed();
  }
}
