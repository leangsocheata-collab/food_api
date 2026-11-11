import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

/// GET /api/payments/:id -> payment detail (bank account to pay, status...)
Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final oid = toOid(id);
  if (oid == null) return fail('Invalid id');
  final p = await (await Database.payments).findOne({'_id': oid});
  final mine = p != null && (p['userId'] as ObjectId).toHexString() == me.id.toHexString();
  if (p == null || (!me.isAdmin && !mine)) return notFound('Payment');
  return ok(p);
}
