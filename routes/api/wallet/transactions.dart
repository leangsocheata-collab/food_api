import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final tx = await Database.transactions;
  return ok(await tx.find(where.eq('userId', me.id).sortBy('createdAt', descending: true).limit(100)).toList());
}
