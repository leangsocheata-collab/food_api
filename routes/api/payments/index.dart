import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;

/// GET /api/payments?status=submitted   (my payments; admin sees all)
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final s = me.isAdmin ? where : where.eq('userId', me.id);
  final status = context.request.uri.queryParameters['status'];
  if (status != null && status.isNotEmpty) s.eq('status', status);
  final payments = await Database.payments;
  return ok(await payments.find(s.sortBy('createdAt', descending: true).limit(100)).toList());
}
