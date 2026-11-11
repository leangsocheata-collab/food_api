import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';

/// GET = my profile, PUT = update name/phone
Future<Response> onRequest(RequestContext context) async {
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final users = await Database.users;
  switch (context.request.method) {
    case HttpMethod.get:
      final u = await users.findOne({'_id': me.id});
      return u == null ? notFound('User') : ok(u);
    case HttpMethod.put:
      final b = await readBody(context);
      final set = <String, dynamic>{
        for (final k in ['name', 'phone'])
          if (b[k] != null) k: b[k].toString(),
      };
      if (set.isEmpty) return fail('Nothing to update');
      await users.updateOne({'_id': me.id}, {r'$set': set});
      return ok(await users.findOne({'_id': me.id}), message: 'Profile updated');
    default:
      return notAllowed();
  }
}
