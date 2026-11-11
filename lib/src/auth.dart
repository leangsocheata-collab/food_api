import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;
import 'database.dart';

class AuthUser {
  AuthUser(this.id, this.role);
  final ObjectId id;
  final String role;
  bool get isAdmin => role == 'admin';
}

String signToken(ObjectId id, String role) => JWT({'id': id.toHexString(), 'role': role})
    .sign(SecretKey(Env.get('JWT_SECRET', 'dev-secret')), expiresIn: const Duration(days: 7));

/// Reads `Authorization: Bearer <token>`. Returns null if missing/invalid.
AuthUser? currentUser(RequestContext context) {
  final h = context.request.headers['authorization'];
  if (h == null || !h.startsWith('Bearer ')) return null;
  try {
    final jwt = JWT.verify(h.substring(7), SecretKey(Env.get('JWT_SECRET', 'dev-secret')));
    final p = Map<String, dynamic>.from(jwt.payload as Map);
    return AuthUser(ObjectId.fromHexString(p['id'] as String), p['role'] as String);
  } catch (_) {
    return null;
  }
}
