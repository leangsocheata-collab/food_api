import 'package:dart_frog/dart_frog.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

Response ok(Object? data, {String? message, int status = 200}) => Response.json(
      statusCode: status,
      body: {'success': true, if (message != null) 'message': message, 'data': serialize(data)},
    );

Response fail(String message, {int status = 400}) =>
    Response.json(statusCode: status, body: {'success': false, 'message': message});

Response unauthorized() => fail('Missing or invalid token', status: 401);
Response forbidden() => fail('Admin only', status: 403);
Response notAllowed() => fail('Method not allowed', status: 405);
Response notFound(String what) => fail('$what not found', status: 404);

/// ObjectId/DateTime -> JSON, `_id` -> `id`, hides passwordHash.
dynamic serialize(dynamic v) {
  if (v is ObjectId) return v.toHexString();
  if (v is DateTime) return v.toUtc().toIso8601String();
  if (v is Map) {
    final out = <String, dynamic>{};
    v.forEach((k, val) {
      if (k == 'passwordHash') return;
      out[k == '_id' ? 'id' : k.toString()] = serialize(val);
    });
    return out;
  }
  if (v is Iterable) return v.map(serialize).toList();
  return v;
}

Future<Map<String, dynamic>> readBody(RequestContext c) async {
  try {
    final b = await c.request.json();
    return b is Map ? Map<String, dynamic>.from(b) : {};
  } catch (_) {
    return {};
  }
}

ObjectId? toOid(String? s) {
  if (s == null) return null;
  try {
    return ObjectId.fromHexString(s);
  } catch (_) {
    return null;
  }
}

double? toDouble(dynamic v) => v is num ? v.toDouble() : double.tryParse('$v');
double round2(double v) => (v * 100).roundToDouble() / 100;
DateTime now() => DateTime.now().toUtc();
