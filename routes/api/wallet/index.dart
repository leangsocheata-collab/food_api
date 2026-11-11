import 'package:dart_frog/dart_frog.dart';
import 'package:food_delivery_api/src/auth.dart';
import 'package:food_delivery_api/src/database.dart';
import 'package:food_delivery_api/src/http.dart';
import 'package:mongo_dart/mongo_dart.dart' show where;

/// GET /api/wallet -> balance + 5 recent activities
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) return notAllowed();
  final me = currentUser(context);
  if (me == null) return unauthorized();
  final user = await (await Database.users).findOne({'_id': me.id});
  final recent = await (await Database.transactions)
      .find(where.eq('userId', me.id).sortBy('createdAt', descending: true).limit(5))
      .toList();
  return ok({'balance': user?['walletBalance'] ?? 0.0, 'recent': recent});
}
