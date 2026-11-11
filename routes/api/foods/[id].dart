import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';

/// GET = food detail, PUT/DELETE = admin
Future<Response> onRequest(RequestContext context, String id) async {
  final oid = toOid(id);
  if (oid == null) return fail('Invalid id');
  final foods = await Database.foods;
  switch (context.request.method) {
    case HttpMethod.get:
      final f = await foods.findOne({'_id': oid});
      return f == null ? notFound('Food') : ok(f);
    case HttpMethod.put:
    case HttpMethod.delete:
      final me = currentUser(context);
      if (me == null) return unauthorized();
      if (!me.isAdmin) return forbidden();
      if (context.request.method == HttpMethod.delete) {
        await foods.deleteOne({'_id': oid});
        return ok(null, message: 'Deleted');
      }
      final b = await readBody(context);
      final set = <String, dynamic>{
        for (final k in ['name', 'description', 'category', 'available'])
          if (b.containsKey(k)) k: b[k],
        if (b['price'] != null) 'price': toDouble(b['price']),
      };
      if (set.isEmpty) return fail('Nothing to update');
      await foods.updateOne({'_id': oid}, {r'$set': set});
      return ok(await foods.findOne({'_id': oid}), message: 'Updated');
    default:
      return notAllowed();
  }
}
