import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;

/// GET = restaurant + its menu, PUT/DELETE = admin
Future<Response> onRequest(RequestContext context, String id) async {
  final oid = toOid(id);
  if (oid == null) return fail('Invalid id');
  final col = await Database.restaurants;
  switch (context.request.method) {
    case HttpMethod.get:
      final r = await col.findOne({'_id': oid});
      if (r == null) return notFound('Restaurant');
      final foods = await Database.foods;
      return ok({...r, 'menu': await foods.find(where.eq('restaurantId', oid)).toList()});
    case HttpMethod.put:
    case HttpMethod.delete:
      final me = currentUser(context);
      if (me == null) return unauthorized();
      if (!me.isAdmin) return forbidden();
      if (context.request.method == HttpMethod.delete) {
        await col.deleteOne({'_id': oid});
        return ok(null, message: 'Deleted');
      }
      final b = await readBody(context);
      final set = <String, dynamic>{
        for (final k in ['name', 'cuisine', 'address'])
          if (b.containsKey(k)) k: b[k],
        if (b['rating'] != null) 'rating': toDouble(b['rating']),
      };
      if (set.isEmpty) return fail('Nothing to update');
      await col.updateOne({'_id': oid}, {r'$set': set});
      return ok(await col.findOne({'_id': oid}), message: 'Updated');
    default:
      return notAllowed();
  }
}
